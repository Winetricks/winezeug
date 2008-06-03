#!/bin/sh
# Script to install Valgrind for Wine to /usr/local/valgrind-svn-wine
# Dan Kegel, 25 Feb 2008
set -x
set -e

# Grab the source
svn co svn://svn.valgrind.org/valgrind/trunk valgrind-svn

# Patch by Dan Kegel & Julian Seward to fix valgrind crash when wine
# updates file times
wget -c http://kegel.com/wine/valgrind/futimesat.patch

cd valgrind-svn

# If this patch doesn't apply, it's probably been fixed already
patch -p0 < ../futimesat.patch

sh autogen.sh

gcc -fno-stack-protector -x c /dev/null > /dev/null 2>&1 && export CC="gcc -fno-stack-protector"

./configure --prefix=/usr/local/valgrind-svn --build=i686-unknown-linux
make
sudo make install
