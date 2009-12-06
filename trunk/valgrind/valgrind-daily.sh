#!/bin/sh
# Script to run "make test" under valgrind and find changes in valgrind results from last time it was run
# Usage: sh tools/valgrind/valgrind-daily.sh
set -x
set -e

# Must be run from the wine tree
WINESRC=`pwd`
# Prepare for calling winetricks
export WINEPREFIX=$HOME/.wine-test
export WINE=$WINESRC/wine
# Convenience variable
WINESERVER=$WINESRC/server/wineserver
if test ! -f $WINESRC/configure 
then
    echo "couldn't find $WINESRC/configure"
    exit 1
fi

# We grep error messages, so make them all English
LANG=C

# Choose the version of valgrind
PATH=/usr/local/valgrind-10903/bin:$PATH

$WINESERVER -k || true
rm -rf $WINEPREFIX

mkdir -p logs

# Build a fresh wine, if desired
if true
then
    ./configure CFLAGS="-g -O0 -fno-inline" --prefix=/usr/local/wine
    make clean
    time make -j4
fi
make testclean

# Load gecko and disable the crash dialog
sh winetricks gecko nocrashdialog heapcheck || true

# keep a notepad up to avoid repeated startup penalty
# even though that hides some errors
$WINESERVER -w
$WINE notepad &

# Should we use date or id from git log?
DATE=`date +%F-%H.%M`
# Get info about what tree we're testing
git log -n 1 > logs/$DATE.log

# Disable any tests known to crash reliably and noisily
# http://bugs.winehq.org/show_bug.cgi?id=20917
touch dlls/d3d8/tests/device.ok
touch dlls/d3d9/tests/device.ok
touch dlls/ddrawex/tests/surface.ok
# http://bugs.winehq.org/show_bug.cgi?id=20925
touch dlls/d3d8/tests/visual.ok
touch dlls/d3d9/tests/visual.ok
touch dlls/d3dx9_36/tests/core.ok

# Disable any tests known to hang reliably
# http://bugs.winehq.org/show_bug.cgi?id=20919
touch dlls/kernel32/tests/process.ok
touch dlls/ole32/tests/marshal.ok
touch dlls/shdocvw/tests/webbrowser.ok
touch dlls/urlmon/tests/url.ok
touch dlls/winmm/tests/mci.ok
touch dlls/winmm/tests/wave.ok

# Finally run the test
export VALGRIND_OPTS="-q --trace-children=yes --track-origins=yes --gen-suppressions=all --suppressions=$PWD/tools/valgrind/valgrind-suppressions --leak-check=full --num-callers=20  --workaround-gcc296-bugs=yes --show-possible=no"
export WINETEST_TIMEOUT=600
export WINETEST_WRAPPER=valgrind
export WINE_HEAP_TAIL_REDZONE=32
time make -k -j2 test >> logs/$DATE.log 2>&1 || true

# Kill off our notepad and any stragglers
$WINESERVER -k || true

# Analyze the log
rm -f vg*.txt
rm -rf logs/$DATE
mkdir logs/$DATE
perl tools/valgrind/valgrind-split.pl logs/$DATE.log
mv vg*.txt logs/$DATE

sh tools/valgrind/valgrind-stats.sh
