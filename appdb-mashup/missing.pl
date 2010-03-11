#!/usr/bin/perl
# Report on which top 50 titles could not be found in appdb
open(FILE, "gamerank-ids.txt") || die;
foreach (<FILE>) {
  chomp;
  $title = $_;
  $title =~ s/.*	// || die "can't parse $_";
  $match = `grep -i "$title" joined-ids.txt`;
  if ($match eq "") {
    print "$_\n";
  }
}
