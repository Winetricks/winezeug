#!/bin/sh
# Usage: sh tools/valgrind-continuous.sh
while true
do
    sh tools/valgrind-sync.sh
    sh tools/valgrind-daily.sh
    sh tools/valgrind-upload.sh $1 $2
    sleep 10
done
