#!/bin/sh
set -e
set -x
rm -rf build
mkdir build
cd build
cmake ..
make
LD_LIBRARY_PATH=. java -classpath Hello.jar Hello
