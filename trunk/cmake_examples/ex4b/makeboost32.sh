#!/bin/sh
# Build boost for 32 bit
# Needed because 64 bit Ubuntu 12.04 doesn't provide 32 bit boost yet
# (see https://bugs.launchpad.net/ubuntu/+source/boost1.48/+bug/918438 )
# Uses opts from http://stackoverflow.com/questions/1357742/how-do-i-force-a-32-bit-build-of-boost-with-gcc
#
# Build only static libraries to save time (and to avoid needing to
# deploy the boost shared libraries; this is a matter of taste)
#
# Note: Have to do 'sudo apt-get install libbz2-dev' first, or compile fails.
#
# Takes about 4 minutes to build on i5 laptop.  Second run is instant.

set -ex

src=`dirname $0`
src=`cd $src; pwd`

top=$src/buildboost32
prefix=$top/prefix
build=$top/build

if ! test -x $prefix/bin/b2
then
    mkdir -p $top
    cd $src
    wget -c http://voxel.dl.sourceforge.net/project/boost/boost/1.48.0/boost_1_48_0.tar.bz2
    cd $top
    rm -rf boost_1_48_0
    tar -xjvf $src/boost_1_48_0.tar.bz2
    cd boost_1_48_0
    cd tools/build/v2
    sh bootstrap.sh
    # Do we even need to install it?
    ./b2 install --prefix=$prefix
fi
if ! test -f $top/prefix/lib/libboost_date_time.a
then
    mkdir -p $build
    cd $top/boost_1_48_0
    PATH=${PATH}:$prefix/bin
    # Exclude python because otherwise build fails with 
    # ./boost/python/detail/wrap_python.hpp:75:24: fatal error: patchlevel.h: No such file or directory
    # because I don't happen to have python-dev installed?
    b2 -j4 --prefix=$prefix --build-dir=$build cflags=-m32 cxxflags=-m32 address-model=32 --without-python threading=multi architecture=x86 instruction-set=i686 link=static stage install
fi

