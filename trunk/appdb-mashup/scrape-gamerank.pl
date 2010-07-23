#!/usr/bin/perl
# Script to scrape gameranking.com's game rankings
# and extract three tables indexed by id: year, rank, and title.
# To get the gamerankings page, use http://www.gamerankings.com/pc/$id-/
#
# TODO: make this only get incremental new results

sub parse_file
{
  $file = $_[0];
  $line = 0;
  open(FILE, $file) || die;
  while (<FILE>) {
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
        } elsif ($line == 2) {
           #            </td>
           /\s*(.*)\s*</ || die;
           $publisher = $1;
        } elsif ($line == 1) {
           # <td><span style="font-size: 35px"><b>91.00%</b></span><br clear="left" />8 Reviews</td>
           /\s*<td><span.*b>(.*)%/ || die;
           $score = $1;
           $titles{$grid} = $title;
           $scores{$grid} = $score;
           $years{$grid} = $year;
           $publishers{$grid} = $publisher;
        }
        $line--;
      }
      if (/<td>PC<\/td>/) {
         $line=3;
      }
    }
}

system("mkdir -p gamerank-cache");

foreach $year (2010)
{
    if (! -f "gamerank-cache/gamerank-$year.rawdat") {
        system("wget -O gamerank-cache/gamerank-$year.rawdat \"http://www.gamerankings.com/browse.html?site=pc&year=$year&numrev=1\"") || warn "wget failed?";
        sleep(1);
    }
    parse_file("gamerank-cache/gamerank-$year.rawdat");
}

sub numerically { $a <=> $b }

open(FILE, "> gamerank-ids.txt") || die;
foreach (sort numerically(keys(%titles))) {
    print FILE "$_	".$titles{$_}."\n";
}
close(FILE);

open(FILE, "> gamerank-scores.txt") || die;
foreach (sort numerically(keys(%scores))) {
    print FILE "$_	".$scores{$_}."\n";
}
close(FILE);

open(FILE, "> gamerank-years.txt") || die;
foreach (sort numerically(keys(%years))) {
    print FILE "$_	".$years{$_}."\n";
}
close(FILE);

open(FILE, "> gamerank-publishers.txt") || die;
foreach (sort numerically(keys(%publishers))) {
    print FILE "$_	".$publishers{$_}."\n";
}
close(FILE);
