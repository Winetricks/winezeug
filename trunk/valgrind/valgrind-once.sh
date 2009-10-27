#!/bin/sh
set -e
set -x
sh tools/valgrind/valgrind-daily.sh
sh tools/valgrind/valgrind-upload.sh $1 $2
