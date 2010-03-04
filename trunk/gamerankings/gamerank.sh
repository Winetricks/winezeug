#!/bin/sh
# Script to scrape gameranking.com's game rankings
# and turn them into a web page suitable for further manual research
# as well as a text file suitable for generating final wiki or web output.
# Format of text file:
#   title|gamerankings.com id|gamerankings.com score|
# To get the gamerankings page, use http://www.gamerankings.com/pc/$grid-/
#
# TODO: make this only get incremental new results

set -x

cat > foo.pl <<"_EOF_"
$html = 0;
$html = 1 if $ARGV[0] eq "--html";
$line = 0;
print "<ul>\n" if $html;
while (<STDIN>) {
    if ($line > 0) {
        if ($line == 3) {
           # <td><a href="/pc/944906-mass-effect-2/index.html">Mass Effect 2</a><br />
           /href="(.*)">(.*)<\/a/ || die;
           $url = $1;
           $title = $2;
           $grid = $url;
           $grid =~ s/-.*//;
           $grid =~ s,/pc/,,;
           $purename = $title;
           $purename =~ s/&//;
           #print "Got url $url, title $title\n";
           #print "$title http://www.gamerankings.com/$url\n";
        } elsif ($line == 2) {
           #            </td>
           /\s(.*)\s*</ || die;
           $publisher = $1;
           #print "Got publisher $publisher\n";
        } elsif ($line == 1) {
           # <td><span style="font-size: 35px"><b>91.00%</b></span><br clear="left" />8 Reviews</td>
           /\s*<td><span.*b>(.*)%/ || die;
           $score = $1;
           #print "Got score $1";
           if ($html) {
               print "<li>$score  $title \
<a href=\"http://google.com/search?q=PC+$purename+site:amazon.com\">Amazon</a> \
<a href=\"http://google.com/search?q=PC+$purename+walkthrough\">Walkthroughs</a> \
<a href=\"http://google.com/search?q=$purename+site:appdb.winehq.org\">Appdb</a> \
<a href=\"http://www.gamerankings.com$url\">Gamerankings</a> \
<a href=\"http://google.com/search?q=$purename+site:wikipedia.org\">Wikipedia</a> \
<a href=\"http://google.com/search?q=$purename+site:playonlinux.com\">PlayOnLinux</a>\n";
           } else {
               print "$title|$score|$grid|\n";
           }
        }
        $line--;
    }
    if (/<td>PC<\/td>/) {
        $line=3;
    }
}
print "</ul>\n" if $html;
_EOF_

for year in 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010
do
    test -f gamerank-$year.rawdat || wget -O gamerank-$year.rawdat "http://www.gamerankings.com/browse.html?site=pc&year=$year"
    perl foo.pl --html < gamerank-$year.rawdat > gamerank-$year-search.html
    if test -f gamerank-$year.txt
    then
        echo not overwriting  gamerank-$year.txt
        exit 1
    fi
    perl foo.pl < gamerank-$year.rawdat > gamerank-$year.txt
    sleep 1
done
