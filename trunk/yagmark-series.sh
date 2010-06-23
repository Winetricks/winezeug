#!/bin/sh
# Usage: sh yagmark-series.sh where-to-upload revisions
set -e
set -x

. ./yagmark-vars

srcdir=`dirname $0`
srcdir=`cd $srcdir; pwd`

url=$1
shift
for rev 
do
    cd $WINEDIR
    sh -x $srcdir/yagmark-sync.sh $rev
    cd $srcdir
    sh -x yagmark-daily.sh $url
    sleep 10
done

