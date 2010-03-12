#!/usr/bin/perl
# Report on which top 50 titles could not be found in appdb

open(FILE, "gamerank-scores.txt") || die;
while (<FILE>) {
   chomp;
   /(\d*)	([^	]*)/ || die;
   $gamerank_scores{$1} = $2;
}
close(FILE);

open(FILE, "gamerank-years.txt") || die;
while (<FILE>) {
   chomp;
   /(\d*)	([^	]*)/ || die;
   $gamerank_years{$1} = $2;
}
close(FILE);

open(FILE, "gamerank-ids.txt") || die;
open(TXT, "> missing-games.txt") || die;
open(HTML, "> missing-games.html") || die;

foreach (<FILE>) {
  chomp;
  $title = $_;
  $title =~ s/.*	// || die "can't parse $_";
  $gamerankings_id = $_;
  $gamerankings_id =~ s/	.*//;
  $match = `grep -i "$title" joined-ids.txt`;
  if ($match eq "") {
    $purename = $title;
    $purename =~ s/&//;
    $year = $gamerank_years{$gamerankings_id};
    $gamerank_score = $gamerank_scores{$gamerankings_id};
    print TXT "$_\n";
    $rows{$title} = "<tr>\
<td>$title</td> \
<td>$year</td> \
<td><a href=\"http://www.gamerankings.com/pc/$gamerankings_id-/\">$gamerank_score</a></td> \
<td><a href=\"http://google.com/search?q=$purename+site:appdb.winehq.org\">search appdb</a></td> \
<td><a href=\"http://www.amazon.com/gp/search/ref=sr_nr_i_1?rh=i:software,k:PC+$purename\">Amazon</a></td> \
<td><a href=\"http://en.wikipedia.org/w/index.php?title=Special:Search&search=$purename&go=Go\">Wikipedia</a></td> \
<td><a href=\"http://google.com/search?q=PC+$purename+walkthrough\">Walkthroughs</a></td> \
</tr>\n";
  }
}
print HTML "<html><body><h1>Gamerankings.com hits not found in wine appdb</h1>(Often these <b>are</b> in the appdb, but as versions, not as freestanding apps; clicking on 'search appdb' should help.)\n<table border=1>\n";
foreach $key (sort(keys(%rows))) {
  print HTML $rows{$key};
}
print HTML "</table></body></html>\n";
