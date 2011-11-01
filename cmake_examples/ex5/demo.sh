#!/bin/sh
set -e
set -x
if ! test -d gtest
then
    test -f gtest-1.6.0.zip || wget http://googletest.googlecode.com/files/gtest-1.6.0.zip
    unzip gtest-1.6.0.zip
    mv gtest-1.6.0 gtest
fi
mkdir build
cd build
cmake ..
make
./mymain
