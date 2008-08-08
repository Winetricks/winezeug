#!/usr/bin/perl
# Given a mess of .txt (patches) and .log (results) files,
# output a static html page explaining what's going on.
# .txt files without matching .log files are in the queue to test.
# .txt files with matching .log files are done.
#
# Output is a table with columns
#  date  author  subject  status

sub my_escape
{
   my $string = $_[0];
   $string =~ s/</\&lt;/;
   $string =~ s/>/\&gt;/;
   return $string;
}

print "<html><body><table border=1>";

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
   my @patch = <FILE>;
   close FILE;
   # Grab date, author, and subject from patch
   my @date = grep(/Date:/, @patch);
   my $date = $date[0];
   $date =~ s/Date:\s*//;
   my @from = grep(/From:/, @patch);
   my $from = $from[0];
   $from =~ s/From:\s*//;
   $from = my_escape($from);
   my @subject = grep(/Subject:/, @patch);
   my $subject = $subject[0];
   $subject =~ s/Subject:\s*//;
   $subject = my_escape($subject);
   
   if ($status eq "queued") {
       $loglink = $status;
   } else {
       $loglink = "<a href=\"$log\">$status</a>";
   }
   print "<tr><td>$date<td>$from<td><a href=\"$patch\">$subject</a><td>$loglink</tr>\n";
}
print "</table></body></html>\n";
