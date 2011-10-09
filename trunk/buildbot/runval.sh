#!/bin/sh
set -x
set -e

cat ~/winezeug/valgrind/valgrind-suppressions ~/winezeug/buildbot/valgrind-blacklist > suppressions

server/wineserver -k

rm -rf ~/.wine

./wine winemine &

sleep 2

VALGRIND_OPTS="--trace-children=yes --track-origins=yes \
  --gen-suppressions=all --suppressions=`pwd`/suppressions \
  --leak-check=no --num-callers=20  --workaround-gcc296-bugs=yes \
  --vex-iropt-precise-memory-exns=yes"
export VALGRIND_OPTS

WINETEST_WRAPPER=valgrind
export WINETEST_WRAPPER

for dir in dlls/*/tests
do
    cd $dir
    make testclean
    make -k test > test.log 2>&1 || true
    cd ../../..
done

kill %1
