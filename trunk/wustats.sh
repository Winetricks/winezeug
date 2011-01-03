#!/bin/sh
# Process web logs from winetricks usage reporting
# Before running, grab the web log manually, place it in usage.log

# See what verbs wisotool2 has today
grep '^w_metadata' wisotool2 | grep -v '()' | awk '!/games/ {print $2}' | sort > wisotool2.loads

# Find what verbs people are using; discard any duplicate verbs from same person,
# then show tally of verbs not yet in wisotool2
cat usage.log |
    cut -d' ' -f1,7 |
    grep winetricks-usage |
    sed 's,/data/winetricks-usage?20101222-,,;s/%20/ /g' |
    perl -e 'while (<STDIN>) {chomp; @x=split(" "); $ip=shift(@x); foreach (@x) { print "$ip $_\n"; }}' > usage.raw

    cat usage.raw |
    sort -u | 
    cut -d' ' -f2 |
    sort |
    uniq -c |
    sort -nr > usage.txt

    cat usage.raw |
    fgrep -w -v -f wisotool2.loads |
    egrep -w -v "fontsmooth-.*|-q|dotnet20sp2|wsh56|comdlg32.ocx" |
    sort -u | 
    cut -d' ' -f2 |
    sort |
    uniq -c |
    sort -nr > usage-left.txt
