#!/bin/sh
set -e
set -x
rm -rf build
mkdir build
cd build
cmake ..
make
./mymain
