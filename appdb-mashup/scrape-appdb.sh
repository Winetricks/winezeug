#!/bin/sh
# Script to scrape the appdb to get a local database of apps.
# It'd be nice to do this via mysql, but oh well.

mkdir -p appdb-cache
cd appdb-cache
if test ! -f 14841.html
then
   i=1
   while test $i -lt 14841
   do
      wget "http://appdb.winehq.org/appview.php?appId=$i" -O $i.html
      # Skip deleted apps
      grep 'You do not have permission to view this entry' $i.html && rm $i.html
      sleep 1
   i=`expr $i + 1`
   done
fi

# "Parse" out titles
# Format: id\ttitle
# Title is currently html escaped, but should probably be utf-8
grep '<title>WineHQ  - ' *.html | sed 's/.html.*WineHQ  - /	/;s,</title>,,' | sort -n > ../appdb-ids.txt

# "Parse" out ratings 
# Format: id\trating [rating [rating]]
grep 'tr class=".*" onmouse' *.html | tr '<' '\012' | egrep '^[0-9]*\.html:|tr class=' | sed 's/onmouse.*//' | grep -v color4 | sed 's/" *$/ /;s/.*"//' | sed 's/\(.*\).html:/:\1	/' | uniq | tr -d '\012' | tr : '\012' | sort -n > ../appdb-scores.txt

