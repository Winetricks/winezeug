#!/bin/sh
# Process web logs from winetricks usage reporting
# Before running, grab the web log manually, place it in usage.log

# See what verbs wisotool2 has today
grep '^w_metadata' winetricks-alpha | grep -v '()' | awk '!/xgames/ {print $2}' | sort > wisotool2.loads

# Find what verbs people are using; discard any duplicate verbs from same person,
# then show tally of verbs not yet in wisotool2
cat usage.log |
    cut -d' ' -f1,7 |
    grep winetricks-usage |
    sed 's,/data/winetricks-usage?[0-9]*-,,;s/%20/ /g' |
    perl -e 'while (<STDIN>) {chomp; @x=split(" "); $ip=shift(@x); foreach (@x) { print "$ip $_\n"; }}' > usage.raw

    cat usage.raw |
    sort -u | 
    cut -d' ' -f2 |
    sort |
    uniq -c |
    sort -nr > usage.txt

    cat usage.raw |
    egrep -v '/data/|winetricks=|Version:|version|dlls' |
    fgrep -w -v -f wisotool2.loads |
    egrep -w -v "fontsmooth-.*|-q|-v|dotnet20sp2|wsh56|comdlg32.ocx|vsm-hard|--optin|npm-repack|vcrun2005sp1|psm=on|fm20|glsl-enable|glsl-disable|ie6_full|cc580|xlive|python|vd=[0-9x]*|list-manual-download|list-installed|list-cached|list-download|list|vbrun60|psm=off|mwo=disabled|dotnet1|dotnet2" |
    sort -u | 
    cut -d' ' -f2 |
    sort |
    uniq -c |
    sort -nr > usage-left.txt
