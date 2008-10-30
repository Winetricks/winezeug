#!/usr/bin/perl
# Given a mess of .txt (patches) and .log (results) files,
# output a static html page explaining what's going on.
# .txt files without matching .log files are in the queue to test.
# .txt files with matching .log files are done.
#
# You may need to do
#  sudo apt-get install libdate-manip-perl
# to get Date::Manip.

use Date::Manip;

binmode \*STDOUT, ":utf8";

sub my_escape
{
   my $string = $_[0];
   $string =~ s/</\&lt;/;
   $string =~ s/>/\&gt;/;
   return $string;
}

print "<html><head>\n";
print "<title>Wine patch status</title>\n";
print "<link rel=\"stylesheet\" href=\"winehq.css\" type=\"text/css\">\n";
print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n";
print "</head><body><table>\n";
print "<col class=date><col class=from><col class=subject><col class=result>\n";
print "<tr>";
print "<th>Date";
print "<th>From";
print "<th>Subject";
print "<th class=result>Status</tr>\n";

open FILE, "ls *.txt | sort -rn |";
my @patches = <FILE>;
close FILE;
my $patch;
for $patch (@patches) {
   chomp($patch);
   my $logname = $patch;
   my $status;
   my $goodness;
   my $commitstatus;
   my $patchresult;
   my $loglink;

   $logname =~ s/\.txt$/.log/;

   if (! -f $logname) {
       $status = "queued";
       $goodness = "0";
   } else {
       open FILE, $logname;
       my @log = <FILE>;
       close FILE;
       my $log = join('', @log);

       # Parse log and decide if build & test succeeded.

       $status = $log;
       # Get last nonblank line in file.
       my $i;
       for ($i = @log - 1; $log[$i] eq "\n"; $i-- && $i >0) { ; }
       $status = $log[$i];
       chomp($status);

       if ($status =~ "Conformance tests ok") {
           $goodness = 1;
       } elsif ($log =~ m/can't find file to patch|hunk FAILED/) {
           $status = "Patch failed.";
           $goodness = "-1";
       } elsif ($log =~ m/Reversed \(or previously applied\) patch/){
           $status = "Patch already in git.";	   
           $goodness = "1";
       } else {
           $goodness = "-1";
       }
   }

   open FILE, $patch;
   binmode FILE, ":utf8";
   my @patch = <FILE>;
   close FILE;

   # Grab date, author, and subject from patch
   my @date = grep(/Date:/, @patch);
   my $date = $date[0];
   $date =~ s/Date:\s*//;
   my @from = grep(/From:/, @patch);
   my $from = $from[0];
   $from =~ s/From:\s*//;
   my @subject = grep(/Subject:/, @patch);
   my $subject = $subject[0];
   $subject =~ s/Subject:\s*//;
   
   my $parsedDate = ParseDate($date);
   $date = UnixDate($parsedDate, "%d-%b-%Y %H:%M");

   $from =~ s/.*<//;
   $from =~ s/>.*//;

   $subject = my_escape($subject);

   if ($goodness == -1) {
       $loglink = "<a href=\"$logname\" class=\"result, fail\">$status</a>";
   } elsif ($goodness == 1) {
       $loglink = "<a href=\"$logname\" class=\"result, pass\">$status</a>";
   } else {
       $loglink = $status;
   }
   print "<tr>";
   print "<td class=date>$date &nbsp;";
   print "<td class=from>$from";
   print "<td class=subject><a href=\"$patch\">$subject</a>";
   print "<td class=status>$loglink";
   print "</tr>\n";
}
print "</table></body></html>\n";
