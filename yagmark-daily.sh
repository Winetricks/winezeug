#!/bin/sh
# Trivial script to build wine and run yagmark ten times, uploading as each iteration is done.
set -e
set -x

build_wine()
{
    rm -rf $WINEOBJ || true
    mkdir -p $WINEOBJ
    cd $WINEOBJ
    $WINEDIR/configure --prefix=/usr/local/wine --without-nas
    ncpus=`awk '/processor/' < /proc/cpuinfo | wc -l`
    njobs=`expr $ncpus + 1`
    make -j$njobs
    cd ~/winezeug
}

case "$OS" in
"") build_wine ;;
esac

NRUNS=${NRUNS:-10}
i=0
while test $i -lt $NRUNS
do
   #sh yagmark 3dmark2000 3dmark2001 3dmark06 heaven2_d3d9 heaven2_gl
   sh yagmark 3dmark2001 3dmark06 heaven2_d3d9 heaven2_gl
   sh yagmark-plot.sh
   i=`expr $i + 1`

   if test "$1" != ""
   then
       rsync -a results/* $1 || rsync -a results/* $1 || echo "oh, well, can't upload"
   fi
done

