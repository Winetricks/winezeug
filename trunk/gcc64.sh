#!/bin/sh
# Build gcc from trunk
# Enable just the C language (since that's all Wine needs)

sudo apt-get build-dep gcc
sudo apt-get install texi2html libgmp3-dev libmpfr-dev
svn checkout svn://gcc.gnu.org/svn/gcc/trunk gcc-svn
cd gcc-svn
contrib/gcc_update
cd ..
rm -rf gcc-build
mkdir gcc-build
cd gcc-build
../gcc-svn/configure --prefix=/usr/local/gcc --enable-languages=c --disable-bootstrap
make
sudo make install

