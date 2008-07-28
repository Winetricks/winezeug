#!/bin/sh
set -e
set -x
sh tools/valgrind-daily.sh
sh tools/valgrind-upload.sh $1 $2
