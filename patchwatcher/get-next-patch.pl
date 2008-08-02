#!/usr/bin/perl
# Retrieve next patch from the specified mailbox, delete it
# Also delete any non-patch email encountered
# Dan Kegel 2008

# TODO: recognize patch series by the convention %d/%d in the subject
# line and only retrieve them in order when the patch series is complete

use strict;
use warnings;
use Mail::POP3Client;
use MIME::Parser;

my $pop = new Mail::POP3Client(
                 USER     => $ENV{"PATCHWATCHER_USER"},
                 PASSWORD => $ENV{"PATCHWATCHER_PASSWORD"},
                 HOST     => $ENV{"PATCHWATCHER_HOST"}
);

## for HeadAndBodyToFile() to use
my $fh = new IO::Handle();

## Initialize stuff for MIME::Parser;
# TODO: stop using outputdir
my $outputdir = "./mimemail";
my $parser = new MIME::Parser;
$parser->output_dir($outputdir);

my $i;
my $done = 0;
## get first patch in pop3 inbox
for ($i = 1; $i <= $pop->Count() && !$done; $i++) {
   my $msg;
   $msg = $pop->HeadAndBody( $i );
   $pop->Delete( $i );
   my $entity = $parser->parse_data($msg);

   $entity->make_singlepart;

   if ($entity->parts < 2) {
	if ($entity->bodyhandle->as_string =~ m/diff/) {
		print "From: ".$entity->head->get('From');
		print "Subject: ".$entity->head->get('Subject');
		print "Date: ".$entity->head->get('Date');
		print "\n";
		print $entity->bodyhandle->as_string;
                $done = 1;                
	}
   } else {
	foreach ($entity->parts) {
		if ($_->bodyhandle->as_string =~ m/diff/) {
			print "From: ".$entity->head->get('From');
			print "Subject: ".$entity->head->get('Subject');
			print "Date: ".$entity->head->get('Date');
		        print "\n";
			print $_->bodyhandle->as_string;
                        $done = 1;                
			last;
		}
	}
   }
}
$pop->Close();
if ($done) {
    exit(0);
} else {
    exit(1);
}

