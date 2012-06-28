#!/bin/sh
# Script to run "make test" under valgrind and find changes in valgrind results from last time it was run
# Usage: sh tools/valgrind/valgrind-daily.sh
set -x
set -e

# Must be run from the wine tree
WINESRC="$HOME/wine-valgrind"
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

if [ -f $WINESERVER ]
then
    $WINESERVER -k || true
fi
rm -rf $WINEPREFIX

mkdir -p logs

# Build a fresh wine, if desired
if true 
then
    if [ -f Makefile ]
    then
        make distclean
    fi
    ./configure CFLAGS="-g -O0 -fno-inline"
    time make -j4
fi

$WINE wineboot

# Disable the crash dialog and enable heapchecking
if test ! -f winetricks
then
    wget http://winezeug.googlecode.com/svn/trunk/winetricks
fi

sh winetricks nocrashdialog heapcheck || true

# start a minimized winemine to avoid repeated startup penalty even though that hides some errors
# Note: running `wineserver -p` is not enough, because that only runs wineserver, not any services
$WINE start /M winemine

# Disable any hanging tests:
touch dlls/d3d8/tests/device.ok
touch dlls/d3d9/tests/device.ok
touch dlls/d3d9/tests/visual.ok 
touch dlls/mshtml/tests/dom.ok
touch dlls/mshtml/tests/event.ok
touch dlls/mshtml/tests/htmldoc.ok
touch dlls/ole32/tests/marshal.ok
touch dlls/ole32/tests/moniker.ok # valgrind crash/hang
touch dlls/shell32/tests/shlexec.ok # pops up lots of 'unknown program' warnings
touch dlls/user32/tests/cursoricon.ok # valgrind crash/hang
touch dlls/urlmon/tests/protocol.ok # hangs
touch dlls/user32/tests/cursoricon.ok # hang
touch dlls/user32/tests/dde.ok # valgrind crash/hang

# Should we use date or id from git log?
DATE=`date +%F-%H.%M`
# Get info about what tree we're testing
git log -n 1 > logs/$DATE.log

# Finally run the tests
export VALGRIND_OPTS="-q --trace-children=yes --track-origins=yes --gen-suppressions=all --suppressions=$WINESRC/tools/valgrind/valgrind-suppressions --suppressions=$WINESRC/tools/valgrind/gst.supp --leak-check=full --num-callers=20  --workaround-gcc296-bugs=yes --vex-iropt-precise-memory-exns=yes"
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
