#!/bin/sh
set -e
set -x

# Do a 64 bit build.  This assumes you're on a 64 bit machine, and have
# already installed c++ and boost, e.g. on Ubuntu, that you've done
#   sudo apt-get install gcc g++ libboost-dev libboost-date-time-dev
FORCE_32_BIT=no
export FORCE_32_BIT
rm -rf build64
mkdir build64
cd build64
cmake ..
make
file mymain
./mymain
cd ..

# Now do a 32 bit build.  There's no nice way to do this; we have
# to jam -m32 flags in by hand
# (see what CMakeLists.txt does with FORCE_32_BIT).
# This assumes you've installed your OS's biarch support packages, e.g.
#  sudo apt-get install ia32-libs gcc-multilib g++-multilib
# and your OS's 32 bit boost packages, e.g.
#  sudo apt-get install libboost-dev:i386 libboost-date-time-dev:i386
# but see https://bugs.launchpad.net/bugs/918438
if true
then
    # Work around ubuntu bug 918438
    sh makeboost32.sh
    boostroot=`pwd`/buildboost32/prefix
    boostarg="-DBOOST_ROOT=$boostroot -DBoost_NO_SYSTEM_PATHS=TRUE"
fi
FORCE_32_BIT=yes
rm -rf build32
mkdir build32
cd build32
cmake --trace $boostarg ..
make VERBOSE=1
file mymain
./mymain
cd ..

