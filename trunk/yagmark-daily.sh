#!/bin/sh
# Trivial script to build wine and run yagmarkk ten times, uploading as each iteration is done.
set -e
set -x

sync_and_build_wine()
{
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
    ncpus=`awk '/processor/' < /proc/cpuinfo | wc -l`
    njobs=`expr $ncpus + 1`
    make -j$njobs
    cd ~/winezeug
}

case "$OS" in
"") sync_and_build_wine ;;
esac

i=0
while test $i -lt 10
do
   sh yagmark heaven2_d3d9 heaven2_gl 3dmark2000 3dmark2001 3dmark06
   i=`expr $i + 1`

   if test "$1" != ""
   then
       rsync -a results/* $1 || rsync -a results/* $1 || echo "oh, well, can't upload"
   fi
done

