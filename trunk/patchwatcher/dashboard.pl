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
print "<tr>";
print "<th>Date";
print "<th>From";
print "<th>Subject";
print "<th>Status</tr>\n";

open FILE, "ls *.txt | sort -n |";
my @patches = <FILE>;
close FILE;
my $patch;
for $patch (@patches) {
   chomp($patch);
   my $log = $patch;
   $log =~ s/\.txt$/.log/;
   if (-f $log) {
       open FILE, "tail -1 $log |";
       $status = <FILE>;
       close FILE;
   } else {
       $status = "queued";
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
   $date = UnixDate($parsedDate, "%d-%b-%Y %H:%m");

   $from =~ s/.*<//;
   $from =~ s/>.*//;

   $subject = my_escape($subject);

   if ($status eq "queued") {
       $loglink = $status;
   } else {
       $loglink = "<a href=\"$log\">$status</a>";
   }
   print "<tr>";
   print "<td class=date>$date &nbsp;";
   print "<td class=from>$from";
   print "<td class=subject><a href=\"$patch\">$subject</a>";
   print "<td class=status>$loglink";
   print "</tr>\n";
}
print "</table></body></html>\n";
