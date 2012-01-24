#!/bin/sh
set -e
set -x

mkdir build64
cd build64
cmake ..
make
./mymain
cd ..

mkdir build32
cd build32
CFLAGS="-m32"
CXXFLAGS="-m32"
export CFLAGS CXXFLAGS
cmake ..
make
./mymain
cd ..
