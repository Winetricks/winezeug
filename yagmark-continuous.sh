#!/bin/sh
# Usage: sh yagmark-continuous.sh where-to-upload
set -e
set -x

WINEDIR=$HOME/wine-git
export WINEDIR
WINE=$WINEDIR/wine
export WINE
WINEPREFIX=$HOME/.wine-yagmark-daily
export WINEPREFIX
srcdir=`dirname $0`
srcdir=`cd $srcdir; pwd`

while true
do
    cd $WINEDIR
    sh -x $srcdir/yagmark-sync.sh
    cd $srcdir
    sh -x yagmark-daily.sh $1
    sleep 10
done
