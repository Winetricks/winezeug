#!/bin/sh
set -x
set -e

SRC=`dirname $0`
SRC=`cd $SRC; pwd`

mkdir /tmp/ex8.$$
cd /tmp/ex8.$$

svn co http://winezeug.googlecode.com/svn/trunk/cmake_examples/ex7/demo demo
svn co http://winezeug.googlecode.com/svn/trunk/cmake_examples/ex7/libsrc libsrc
sh $SRC/../ex7/demo.sh
