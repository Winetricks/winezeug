#!/bin/sh
set -x

# Don't even try to handle non-english titles yet
LANG=C

# This is a real tab char, used to delimit fields of our data files
TAB="	"

# Collect data from appdb.winehq.org
sh scrape-appdb.sh
# Collect top 50 title data from gamerankings.com
perl scrape-gamerank.pl

# Apply bandaids to convert appdb titles to match gamerank titles.
# This needs a lot of manual expanding.
# Perhaps the corrections should be in the appdb rather than here.
# Only worth doing for gold or platinum titles...
sed -f corrections.sed < appdb-ids.txt > appdb-ids-converted.txt

# Join the two.  Filter out any appdb entries with utf-8 or html-escaped text, as it makes join complain about unsorted files.
sort -f -k 2 < appdb-ids-converted.txt | grep -v '&#' | cat -v | grep -v 'M-.*M-' > appdb-ids-sorted.tmp
sort -f -k 2 < gamerank-ids.txt > gamerank-ids-sorted.tmp
join -i -t"$TAB" -j 2  appdb-ids-sorted.tmp gamerank-ids-sorted.tmp > joined-ids.txt
# Format: title\tAppdbId\tGamerankingId

# Now find the appdb scores for each top-50 game
sort -k 2 -t"$TAB" < joined-ids.txt > joined-ids-sorted.tmp
sort < appdb-scores.txt > appdb-scores-sorted.tmp
join  -i -t"$TAB" -1 2 joined-ids-sorted.tmp appdb-scores-sorted.tmp > joined-scores.txt

# Report on which top 50 titles couldn't be matched in appdb
perl missing.pl
ranked=`wc -l < gamerank-ids.txt`
matched=`wc -l < joined-ids.txt`
missing=`wc -l < missing.txt`
echo Of $ranked ranked games, $matched were found in the appdb, and $missing were not.
echo The most common reason for mismatches is the appdb using a different name for the game than gamerankings.com.
echo To fix this, add a correction to corrections.sed.

# And finally generate a pretty html report of good apps.
perl report.pl 'Gold|Platinum' > good-games.html
perl report.pl 'Garbage|Bronze|Silver' > bad-games.html
