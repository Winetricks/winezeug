#!/bin/sh
set -e
set -x
WINEDIR=$HOME/wine-git
WINE=$WINEDIR/wine
export WINE
WINEPREFIX=$HOME/.wine-yagmark-daily
export WINEPREFIX

cd $WINEDIR
make clean
git diff > foo.diff
patch -R -p1 < foo.diff
git pull
patch -p1 < 3dmark06.patch

./configure --prefix=/usr/local/wine --without-nas
make -j3
cd ~/winezeug

i=0
while test $i -lt 10
do
   sh yagmark 3dmark2000 3dmark2001 3dmark06
   i=`expr $i + 1`
done

if test "$1" != ""
then
    rsync -a results/* $1
fi
