#!/usr/bin/perl
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
my $outputdir = "./mimemail";
my $parser = new MIME::Parser;
$parser->output_dir($outputdir);

my $i;
## process all messages in pop3 inbox
for ($i = 1; $i <= $pop->Count(); $i++) {
   my $msg;
   $msg = $pop->HeadAndBody( $i );
   my $entity = $parser->parse_data($msg);

   $entity->make_singlepart;

   if ($entity->parts < 2) {
	if ($entity->bodyhandle->as_string =~ m/diff/) {
		print $entity->head->get('Date');
		print $entity->head->get('From');
		print $entity->head->get('Subject');
		print $entity->bodyhandle->as_string;
	}
   } else {
	foreach ($entity->parts) {
		if ($_->bodyhandle->as_string =~ m/diff/) {
			print $entity->head->get('Date');
			print $entity->head->get('From');
			print $entity->head->get('Subject');
			print $_->bodyhandle->as_string;
			last;
		}
	}
   }
}


