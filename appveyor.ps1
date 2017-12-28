
$ErrorActionPreference = "Stop"

function clone($url, $path, $branch)
{
    foreach($i in 0..4)
    {
        if(git clone --branch "$branch" "$url" "$path")
        {
            break
        }
        elseif($i -lt 4)
        {
            sleep $(1 -shl $i)
        }
        else
        {
            echo "Failed to clone: ${url}"
            exit 1
        }
    }
}

if(!(Test-Path "./gnumake/make.exe"))
{
    mkdir gnumake
    cd gnumake

    appveyor DownloadFile "https://ftp.gnu.org/gnu/make/make-4.2.tar.gz" -FileName make.tar.gz

    7z x make.tar.gz -so | 7z x -si -ttar > $null
    cd make-4.2

    cmd /C '"c:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64 && .\build_w32.bat > $null'

    cp WinRel/gnumake.exe ../make.exe
    cd ../..
}

if($env:D_COMPILER == "dmd")
{
    #appveyor DownloadFile "http://downloads.dlang.org/releases/2.x/${D_VERSION}/dmd.${D_VERSION}.windows.7z" -FileName dmd2.7z
    appveyor DownloadFile "http://nightlies.dlang.org/dmd-master-2017-12-22/dmd.master.windows.7z" -FileName dmd2.7z
    7z x dmd2.7z > $null

    $env:PATH = "$pwd/dmd2/windows/bin/;$env:PATH"
    $env:DMD = "C:/projects/dmd2/windows/bin/dmd.exe"

    dmd --version
}

foreach($proj in "druntime", "phobos")
{
    if(($env:APPVEYOR_REPO_BRANCH -ne "master") -and ($env:APPVEYOR_REPO_BRANCH -ne "stable") -and
        !(git ls-remote --exit-code --heads https://github.com/dlang/$proj.git $env:APPVEYOR_REPO_BRANCH > $null))
    {
        # use master as fallback for other repos to test feature branches
        clone https://github.com/dlang/$proj.git $proj master
    }
    else
    {
        clone https://github.com/dlang/$proj.git $proj $APPVEYOR_REPO_BRANCH
    }
}

cd C:/projects/dmd/src
make -f win64.mak reldmd DMD=../src/dmd

cd C:/projects/druntime
make -f win64.mak DMD=../dmd/src/dmd

cd C:/projects/phobos
make -f win64.mak DMD=../dmd/src/dmd

cp C:/projects/phobos/phobos64.lib C:/projects/dmd/

$env:OS = "Win_64"
$env:CC = 'c:/"Program Files (x86)"/"Microsoft Visual Studio 14.0"/VC/bin/amd64/cl.exe'
$env:MODEL = "64"
$env:MODEL_FLAG =" -m64"

cd C:/projects/dmd/test

bash --version
bash -c '../../gnumake/make -j2 all MODEL=$env:MODEL MODEL_FLAG=$env:MODEL_FLAG LIB="../../phobos;$env:LIB"'
