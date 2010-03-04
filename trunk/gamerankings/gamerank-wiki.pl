print "||Name&nbsp;||Appdb&nbsp;||Gamerankings&nbsp;||\n";
while (<STDIN>) {
    chomp;
    ($name, $score, $grid, $appdbid) = split(/\|/);
    $purename = $name;
    $purename =~ s/&//;
    print "||";
    print "$name||";
    if ($appdbid != 0) {
        $appdb = "http://appdb.winehq.org/appview.php?iAppId=$appdbid";
        open(FILE, "wget -O- \"$appdb\"|") || die "can't wget";
        @ratings=grep(/>Rating</, <FILE>);
        $rating = "";
        foreach $level ("garbage", "bronze", "silver", "gold", "platinum") {
           if (grep(/>$level</i, @ratings)) {
               $rating .= "/" if ($rating ne "");
               $rating .= $level;
           }
        }
        $rating = "?" if ($rating eq "");
        print "[$appdb $rating]||";
    } else {
       print "no||";
    }
    print "[http://www.gamerankings.com/pc/$grid-/ $score]||";
    print "\n";
}
