#!/bin/sh

set -e -v

echo "C_COMPILER: $C_COMPILER"
echo "D_COMPILER: $D_COMPILER"
echo "D_VERSION: $D_VERSION"

cd /c/projects/

if [ $D_COMPILER == "dmd" ]; then
    appveyor DownloadFile "http://downloads.dlang.org/releases/2.x/${D_VERSION}/dmd.${D_VERSION}.windows.7z" -FileName dmd2.7z
    7z x dmd2.7z > /dev/null
    export PATH=$PWD/dmd2/windows/bin/:$PATH
    export DMD=/c/projects/dmd2/windows/bin/dmd.exe
    dmd --version
fi

if [ $APPVEYOR_REPO_TAG == true ]; then
    git clone --branch $APPVEYOR_REPO_TAG_NAME https://github.com/dlang/druntime
    git clone --branch $APPVEYOR_REPO_TAG_NAME https://github.com/dlang/phobos
else
    git clone --branch v2.076.1 https://github.com/dlang/druntime
    git clone --branch v2.076.1 https://github.com/dlang/phobos
fi


cd /c/projects/dmd/src
make -f win64.mak reldmd DMD=../src/dmd

cd /c/projects/druntime
make -f win64.mak DMD=../dmd/src/dmd DFLAGS="-m64 -conf= -debug -g -dip1000 -inline -w -Isrc -Iimport"

cd /c/projects/phobos
make -f win64.mak DMD=../dmd/src/dmd DFLAGS="-conf= -m64 -debug -g -w -de -dip25 -I..\druntime\import"

cp /c/projects/phobos/phobos64.lib /c/projects/dmd/

export OS="Win_64"
export CC='c:/"Program Files (x86)"/"Microsoft Visual Studio 14.0"/VC/bin/amd64/cl.exe'
export MODEL="64"
export MODEL_FLAG="-m64"

cd /c/projects/dmd/test
# ../../make/make -j3 all MODEL=$MODEL MODEL_FLAG=$MODEL_FLAG LIB="../../phobos;$LIB"

