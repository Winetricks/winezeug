#!/bin/sh
# Script to run "make test" under valgrind and find changes in valgrind results from last time it was run
# Usage: sh tools/valgrind/valgrind-daily.sh
set -x
set -e

# Must be run from the wine tree
WINESRC="$HOME/wine-git"
# Prepare for calling winetricks
export WINEPREFIX=$HOME/.wine-test
export WINE=$WINESRC/wine
# Convenience variable
WINESERVER=$WINESRC/server/wineserver

cd $WINESRC

if test ! -f $WINESRC/configure 
then
    echo "couldn't find $WINESRC/configure"
    exit 1
fi

# We grep error messages, so make them all English
LANG=C

$WINESERVER -k || true
rm -rf $WINEPREFIX

mkdir -p logs

# Build a fresh wine, if desired
if true
then
    ./configure CFLAGS="-g -O0 -fno-inline"
    make clean
    time make -j4
fi
make testclean

# Load gecko and disable the crash dialog
if test ! -f winetricks
then
    wget http://winezeug.googlecode.com/svn/trunk/winetricks
fi

sh winetricks nocrashdialog heapcheck || true

# start a minimized winemine to avoid repeated startup penalty even though that hides some errors
# Note: running `wineserver -p` is not enough, because that only runs wineserver, not any services
$WINE start /M winemine

# Should we use date or id from git log?
DATE=`date +%F-%H.%M`
# Get info about what tree we're testing
git log -n 1 > logs/$DATE.log

# Finally run the tests
export VALGRIND_OPTS="-q --trace-children=yes --track-origins=yes --gen-suppressions=all --suppressions=$WINESRC/tools/valgrind/valgrind-suppressions --leak-check=full --num-callers=20  --workaround-gcc296-bugs=yes --vex-iropt-precise-memory-exns=yes"
export WINETEST_TIMEOUT=600
export WINETEST_WRAPPER=valgrind
export WINE_HEAP_TAIL_REDZONE=32
time make -k test >> logs/$DATE.log 2>&1 || true

# Kill off winemine and any stragglers
$WINESERVER -k || true

# Analyze the log
rm -f vg*.txt
rm -rf logs/$DATE
mkdir logs/$DATE
perl tools/valgrind/valgrind-split.pl logs/$DATE.log
mv vg*.txt logs/$DATE

sh tools/valgrind/valgrind-stats.sh
