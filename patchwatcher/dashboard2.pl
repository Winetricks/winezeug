#!/usr/bin/perl
# Given a mess of .patch (patches) and .log (results) files,
# output a static html page explaining what's going on.
# .patch files without matching .log files are in the queue to test.
# .patch files with matching .log files are done.
#
# You may need to do
#  sudo apt-get install libdate-manip-perl
# to get Date::Manip.

use Date::Manip;

binmode \*STDOUT, ":binary";

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
print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=Latin1\" />\n";
print "</head><body><table>\n";
print "<col class=\"date\"><col class=\"from\"><col class=\"subject\"><col class=\"result\">
\n";
print "<tr>";
print "<th>Date";
print "<th>From";
print "<th>Subject";
print "<th class=result>Status</tr>\n";

open FILE, "find outbox sent slave* -name '[1-9]*' -type d | sort -t/ -k 2rn |";
my @jobs = <FILE>;
close FILE;
my $job;
for $job (@jobs) {
  chomp ($job);
  open FILE, "ls $job/*.patch | sort -rn |";
  my @patches = <FILE>;
  close FILE;
  my $patch;

  for $patch (@patches) {
   chomp($patch);
   my $log = $patch;
   $log =~ s/.patch$/.log/;
   if (-f $log) {
       open FILE, "grep . < $log | tail -1 |";
       $status = <FILE>;
       chomp($status);
       close FILE;
   } else {
       $status = "queued";
   }
   open FILE, $patch;
   binmode FILE, ":binary";
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
   $date = UnixDate($parsedDate, "%d-%b-%Y %H:%m");

   $from =~ s/.*<//;
   $from =~ s/>.*//;

   $subject = my_escape($subject);

   $patch =~ s/[^\/]*\///;
   $log =~ s/[^\/]*\///;

   if ($status eq "queued") {
       $loglink = $status;
   } elsif ($status =~ "Patchwatcher:OK") {
       $loglink = "<a href=\"$log\" class=\"result, pass\">$status</a>";
   } else {
       $loglink = "<a href=\"$log\" class=\"result, fail\">$status</a>";
   }
   print "<tr>";
   print "<td class=date>$date &nbsp;";
   print "<td class=from>$from";
   print "<td class=subject><a href=\"$patch\">$subject</a>";
   print "<td class=status>$loglink";
   print "</tr>\n";
  }
}
print "</table></body></html>\n";
