#!/usr/bin/perl
# Get and remove all complete patches/patch series from the specified mailbox
# Drop any patch older than three days 
# Also delete any non-patch email encountered
# Argument is number of first patch to output.
#
# Patches are output as %d.txt in utf-8 format.
# Once a patch has been fully dealt with (e.g. not a patch, multiple patches,
# fails to apply, fails to build, or builds successfully),
# a corresponding .log is created.  The last line of the .log file
# is a short status message suitable for displaying in a dashboard.
# Any .txt file without a matching .log file is ready to be applied and tested.

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
    print "Usage: perl get-patches.pl starting-patch-number\n";
    exit(1);
}

my $patches_written = 0;

sub output_message
{
    my $header = $_[0];
    my $body = $_[1];
    my $status = $_[2];

    open FILE, "> $curmsg.txt" || die "can't create $curmsg.txt";
    binmode FILE, ":utf8";

    print FILE "From: ". decode('MIME-Header', $header->get('From'));
    print FILE "Subject: ".$header->get('Subject');
    print FILE "Date: ".$header->get('Date');
    print FILE "\n";
    print FILE $body;

    close FILE;

    if (defined($status)) {
        open FILE, "> $curmsg.log" || die "can't create $curmsg.log";
    
        print FILE $status;
    
        close FILE;
    } else {
        # Remember that we did output a real patch
        $patches_written++;
    }
    $curmsg++;
}

# Is a body string a patch?
sub is_patch
{
    my $body = $_[0];

    return $body =~ m/^diff|\ndiff|^\+\+\+ |\n\+\+\+ /;
}

sub netascii_to_host
{
   my $body = $_[0];

   $body =~ s/\015//g;
   return $body;
}

# Given an index into the mailbox, return a triple
# ($head_object, $message_as_plaintext, $numpatches)
# Flattens attachments.
# Third element is number of patches; 0 means it contains no patches, 
# 2 or higher means somebody attached multiple patches 
# (or had one inline and one attached)
sub retrieve_message
{
   my $index = $_[0];
   my $msg = $pop->HeadAndBody( $index );
   my $entity = $parser->parse_data($msg);
   my $text = "";
   my $numpatches = 0;

   # Turns out preamble is just "This is a MIME message" usually.
   #if (defined($entity->preamble)) {
   #   foreach (@{$entity->preamble}) {
   #      $text .= $_;
   #   }
   #   $text .= "\n";
   #}
   foreach ($entity->parts_DFS) {
      $text .= "\n";
      if ($_->effective_type eq "text/html") {
          $text .= "[HTML message skipped]\n";
      } else {
          $text .= $_->bodyhandle->as_string if defined($_->bodyhandle);
          $numpatches++ if (defined($_->bodyhandle) && is_patch($_->bodyhandle->as_string));
      }
   }
   #if (defined($entity->epilogue)) {
   #   $text .= "\n";
   #   foreach (@{$entity->epilogue}) {
   #      $text .= $_;
   #   }
   #}

   return ($entity->head, netascii_to_host($text), $numpatches);
}

my $series_sender = "";
my $series_num_patches;
my @series_headers;
my @series_bodies;
my @series_indices;

sub consume_series_patch
{
    my $header = $_[0];
    my $body = $_[1];
    my $index = $_[2];
    my $which_patch = $_[3];
    my $num_patches = $_[4];

    my $sender = decode('MIME-Header', $header->get('From'));

    if ($series_sender eq "") {
       #print "Starting series; sender $sender, num_patches $num_patches, subject ".$header->get('Subject')."\n";
       $series_sender = $sender;
       $series_num_patches = $num_patches;
    }

    if ($series_sender ne $sender) {
        #print "Ignoring series for now, will try later; sender $sender, num_patches $num_patches, subject ".$header->get('Subject')."\n";
        # can't handle multiple series at once just yet, let it sit
        return;
    }
    #print "Saving patch $which_patch\n";
    $series_headers[$which_patch] = $header;
    $series_bodies[$which_patch] = $body;
    $series_indices[$which_patch] = $index;

    # Is the series complete?
    my $j;
    for ($j=1; $j <= $series_num_patches; $j++) {
        last if (! defined($series_indices[$j]));
    }
    if ($j == $series_num_patches+1) {
        # Yes!  Output them all.
        for ($j=1; $j <= $series_num_patches; $j++) {
            #print "Outputting patch $j of $series_num_patches\n";
            output_message($series_headers[$j], $series_bodies[$j], undef);
            $pop->Delete( $series_indices[$j] );
        }
        @series_headers = ();
        @series_bodies = ();
        @series_indices = ();
        $series_sender = "";
        $series_num_patches = "";
    }
    # else let it sit in mailbox until it's complete.
}

sub consume_patch
{
    my $header = $_[0];
    my $body = $_[1];
    my $index = $_[2];

    if ($header->get('Subject') !~ /(\d+)\/(\d+)/) {
        output_message($header, $body, undef);
        $pop->Delete( $index );
    } else {
        # part of sequence 
        my $which_patch = $1;
        my $num_patches = $2;
        if ($which_patch == 0) {
            # Zeroth patch in series is supposed to be just explanation?
            output_message($header, $body, "patch zero of a series");
            $pop->Delete( $index );
        } else {
            # Patches that are part of a series get special treatment
            consume_series_patch($header, $body, $index, $which_patch, $num_patches);
        }
    }
}

my $i;
for ($i = 1; $i <= $pop->Count(); $i++) {
    my ($head, $body, $numpatches_in_msg) = retrieve_message($i);
    my $from = $head->get('From');
    my $subject = $head->get('Subject');

    # Delete messages without body?
    if (!defined($body)) {
        output_message($head, $body, "No body");
        print "no body: $subject\n";
        $pop->Delete( $i );
        next;
    }

    if ($numpatches_in_msg == 0) {
        output_message($head, $body, "No patch detected");
        print "No patch: $curmsg, $from, $subject\n";
        $pop->Delete( $i );
        next;
    }

    if ($numpatches_in_msg > 1) {
        output_message($head, $body, "Multiple patches detected, ignoring");
        print "Multiple patches in one message not allowed (this is a wine-patches policy): $subject\n";
        $pop->Delete( $i );
        next;
    }

    # TODO: delete patches older than three days
    #my $date = $head->get('Date');
    #if ($today - $date  > 3 days) {
    #    output_message($head, $body, "Old message, ignoring");
    #    $pop->Delete( $i );
    #   next;
    #}
 
    consume_patch($head, $body, $i);
}
$pop->Close();

if ($patches_written > 0) {
    exit(0);
} else {
    exit(1);
}

