#!/bin/sh
# Script to generate new blacklist
# Run this after patchwatcher has been running a long time
# But delete valid test failures first, or remove them from the resulting
# blacklist!

if test "$1" = ""
then
   N=1
else
   N=$1
fi
cd patches
cat *.testlog | perl ../get-dll.pl | egrep ": Test failed: |: Test succeeded inside todo block: |^make\[.*\]: \*\*\* \[" | sort | uniq -c | sort -n > baseline.testdat.count 
awk "\$1 > $N" < baseline.testdat.count | sed 's/^ *[0-9]* *//' | sort > baseline.testdat.big
diff -u baseline.testdat baseline.testdat.big  | grep -v '^+++' | grep '^+' | sed 's/^+//;s/:[0-9][0-9]*.*//;s/make\[1\]: \*\*\* \[//;s/\] Error.*//' | sort -u  | (sort -u | tr '\012' '|' ; echo "") | sed 's/.$//' 
