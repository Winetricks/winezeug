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
   print "$i \n";
   my $msg;
   $msg = $pop->HeadAndBody( $i );
   my $entity = $parser->parse_data($msg);

   print $parser->results->top_head->get('Date');
   print $parser->results->top_head->get('From');
   print $parser->results->top_head->get('Subject');
   $entity->dump_skeleton;

}


