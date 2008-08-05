#!/usr/bin/perl
# Get and remove all messages from the specified mailbox
# Messages are output as flattened text files named %d.txt in utf-8.
# Argument is number of first message to output.

# Dan Kegel 2008

use strict;
use warnings;
use Mail::POP3Client;
use MIME::Parser;
use Encode qw/decode/; 

my $pop = new Mail::POP3Client(
                 USER     => $ENV{"PATCHWATCHER_USER"},
                 PASSWORD => $ENV{"PATCHWATCHER_PASSWORD"},
                 HOST     => $ENV{"PATCHWATCHER_HOST"}
);

## Initialize stuff for MIME::Parser;
# TODO: stop using outputdir
my $outputdir = "./mimemail";
my $parser = new MIME::Parser;
$parser->output_dir($outputdir);

my $curmsg = $ARGV[0];
if ($curmsg eq "") {
    print "Usage: perl get-message.pl starting-message-number\n";
    exit(1);
}

sub netascii_to_host
{
   my $body = $_[0];

   $body =~ s/\015//g;
   return $body;
}

# Given an index into the mailbox, return a pair
# ($head_object, $message_as_plaintext)
# Flattens attachments.
sub retrieve_message
{
   my $index = $_[0];
   my $msg = $pop->HeadAndBody( $index );
   my $entity = $parser->parse_data($msg);
   my $text = "";
   my $partnum;

   $entity->dump_skeleton(\*STDOUT);

   $partnum = 1;

   if (defined($entity->preamble)) {
      foreach (@{$entity->preamble}) {
         $text .= $_;
      }
      $text .= "\n";
   }
   foreach ($entity->parts_DFS) {
      if (defined($_->bodyhandle) && $_->bodyhandle->as_string =~ m/ARRAY/) {
         print "hey! partnum $partnum funny\n";
      }
      $partnum++;
      $text .= $_->bodyhandle->as_string if defined($_->bodyhandle);
   }
   if (defined($entity->epilogue)) {
      $text .= "\n";
      foreach (@{$entity->epilogue}) {
         $text .= $_;
      }
   }

   print $text;

   return ($entity->head, netascii_to_host($text));
}

my $msgs_written = 0;

sub output_message
{
    my $header = $_[0];
    my $body = $_[1];
    open FILE, "> $curmsg.txt" || die "can't create $curmsg.txt";
    binmode FILE, ":utf8";
    $curmsg++;
    $msgs_written++;

    print FILE "From: ". decode('MIME-Header', $header->get('From'));
    print FILE "Subject: ". decode('MIME-Header', $header->get('Subject'));
    print FILE "Date: ".$header->get('Date');
    print FILE "\n";
    print FILE $body;

    close FILE;
}

my $i;
for ($i = 1; $i <= $pop->Count(); $i++) {
    my ($head, $body) = retrieve_message($i);
    output_message($head, $body);
}
$pop->Close();

if ($msgs_written > 0) {
    exit(0);
} else {
    exit(1);
}

