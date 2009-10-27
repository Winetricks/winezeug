#!/bin/sh
# Usage: sh tools/valgrind/valgrind-continuous.sh
set -e
set -x
while true
do
    sh tools/valgrind/valgrind-sync.sh
    sh tools/valgrind/valgrind-daily.sh
    sh tools/valgrind/valgrind-upload.sh $1 $2
    sleep 10
done
