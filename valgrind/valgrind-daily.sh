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

# Choose the version of valgrind
PATH=/usr/local/valgrind-10903/bin:$PATH

$WINESERVER -k || true
rm -rf $WINEPREFIX

mkdir -p logs

# Build a fresh wine, if desired
if true
then
    git pull
    ./configure CFLAGS="-g -O0 -fno-inline" --prefix=/usr/local/wine
    make clean
    time make -j3
fi
make testclean

# Load gecko and disable the crash dialog
sh winetricks gecko nocrashdialog || true

# keep a notepad up to avoid repeated startup penalty
# even though that hides some errors
$WINESERVER -w
$WINE notepad &

# Should we use date or id from git log?
DATE=`date +%F-%H.%M`
# Get info about what tree we're testing
git log -n 1 > logs/$DATE.log

# Finally run the test
export VALGRIND_OPTS="-q --trace-children=yes --track-origins=yes --gen-suppressions=all --suppressions=$PWD/tools/valgrind/valgrind-suppressions --leak-check=full --num-callers=20  --workaround-gcc296-bugs=yes --show-possible=no"
export WINETEST_WRAPPER=valgrind
time make -k test >> logs/$DATE.log 2>&1 || true

# Kill off our notepad and any stragglers
$WINESERVER -k || true

# Analyze the log
rm -f vg*.txt
rm -rf logs/$DATE
mkdir logs/$DATE
perl tools/valgrind/valgrind-split.pl logs/$DATE.log
mv vg*.txt logs/$DATE

# Generate histogram of errors
cat logs/$DATE.log |
egrep -C3 'uninitialised|Unhandled exception:|Invalid read|Invalid write|Invalid free|Source and desti|Mismatched free|unaddressable byte|vex x86' | grep == | sed 's/.*=//' > sum
cat sum | 
sed "/Warning: set add/s/.*//" |
sed "/ERROR SUMMARY/s/.*//" |
sed "/malloc.free/s/.*//" |
sed "/Reachable blocks/s/.*//" |
sed "/searching for pointer/s/.*//" |
sed "/Your program just tried to execute an instruction that Valgrind/s/.*//" |
sed "/did not recognise. There are two possible reasons for this.*/s/.*//" |
sed "/More than 100 errors detected/s/.*//" |
sed "/will still be recorded/s/.*//" |
sed "/For counts of detected/s/.*//" |
sed "/suppressed:/s/.*//" |
sed "/Thread [0-9]*:/s/.*//" |
sed "/^yes/s/.*//" |
sed 's,/home/dank/.wine-test/drive_c/windows/,,' |
cat > sum2
cat sum2 | sed 's/by 0x[0-9a-fA-F]*:/by /' | sed 's/at 0x[0-9a-fA-F]*:/at /'  > sum3
sed 's/^ \([^ ]\)/|\1/' < sum3 > sum4
cat sum4 | tr '\012' '\011' | tr '|' '\012' | sed 's/  */ /g' | sed 's/[ 	]*$//' | grep . > sum5
sort < sum5 | uniq -c | sort -rn > logs/$DATE-count-by-error.txt

# Generate count of errors by file
for a in `cd logs/$DATE; ls *.txt | grep -v .-diff`
do
    echo -n "$a    "
    egrep  'uninitialised|Unhandled exception:|Invalid read|Invalid write|Invalid free|Source and desti|Mismatched free|unaddressable byte|vex x86' < logs/$DATE/$a | wc -l || true
done | sort --k 2n > logs/$DATE-count-by-file.txt

PREV=`ls -d logs/????-??-??-??.?? | tail -2 | head -1`
diff -Nu  -x '*diff.txt' $PREV logs/$DATE >  logs/$DATE-diff.txt || true
cat logs/$DATE-diff.txt | egrep '^[-+].*(uninitialised|Unhandled exception:|Invalid read|Invalid write|Invalid free|Source and desti|Mismatched free|unaddressable byte|Uninitialised value was created|vex x86)|diff' >  logs/$DATE-summary.txt || true
cd logs/$DATE
for file in `ls vg*.txt | grep -v .-diff.txt`
do
	out=`basename $file .txt`-diff.txt
	diff -Nu ../../$PREV/$file $file > $out || true
done
chmod 644 *
chmod 755 .

