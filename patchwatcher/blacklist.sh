#!/bin/sh
# Script to generate new blacklist
# Run this after patchwatcher has been running a long time
# But delete valid test failures first, or remove them from the resulting
# blacklist!

TOP=`pwd`

if test "$1" = ""
then
   N=1
else
   N=$1
fi
set -x

cd shared/sent
cat */*.testlog | perl $TOP/get-dll.pl | egrep ": Test failed: |: Test succeeded inside todo block: |^make\[.*\]: \*\*\* \[" | sort | uniq -c | sort -n > sent.testdat.count 
awk "\$1 > $N" < sent.testdat.count | sed 's/^ *[0-9]* *//' | sort > sent.testdat

cd ..
for a in slave*
do
   diff -u $a/baseline.testdat sent/sent.testdat  | grep -v '^+++' | grep '^+' | sed 's/^+//;s/:[0-9][0-9]*.*//;s/make\[1\]: \*\*\* \[//;s/\] Error.*//' | sort -u  > $a/new-blacklist.testdat
done
