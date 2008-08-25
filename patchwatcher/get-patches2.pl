#!/usr/bin/perl
# Get and remove all complete patches from the specified mailbox
# Each patch is output into a separate numbered directory as file 1.patch,
# except that patches in a series are stored in the same directory
# with names 1.patch, 2.patch, etc.
#
# Argument is number of first output directory to create.
# The POP3 account to access is taken from the environment variables
# PATCHWATCHER_{USER,PASSWORD,HOST}.
#
# Patches are output as $seriesnum/$patchnum.patch in utf-8 format.
# If any problem is found with a patch, outputs the patch as usual,
# then saves a description of the problem in a file next to it with suffix .log.
# For instance, patches older than two days are considered stale
# (as it's either a mail problem or a bug in our patch series handing).
# Exception: webmail cookie messages are simply ignored and deleted,
# since they aren't really messages.
#
# Copyright 2008 Google (Dan Kegel)

use strict;
use warnings;
use Date::Manip;
use Mail::POP3Client;
use MIME::Parser;
use Encode qw/decode/; 
use Encode qw/encode/; 

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

my $curseries = $ARGV[0];
if ($curseries eq "") {
    print "Usage: perl get-patches.pl starting-series-number\n";
    exit(1);
}

my $patches_written = 0;

my $curseries_length;
my $curseries_nbad;

sub output_series_start
{
    $curseries_length = 0;
    $curseries_nbad = 0;
}

# Write a single message of a series to disk
sub output_message
{
    my $header = $_[0];
    my $body = $_[1];
    my $status = $_[2];
    my $patchnum = $_[3];
    my $headertxt;

    my $patchfile = "tmp.$curseries/$patchnum.patch";
    my $logfile = "tmp.$curseries/$patchnum.log";

    if ($patchnum == 1) {
        mkdir("tmp.$curseries");
    }

    open FILE, "> $patchfile" || die "can't create $patchfile";
    binmode FILE, ":bytes";

    $headertxt = 
        "From: ". decode('MIME-Header', $header->get('From')).
        "Subject: ".decode('MIME-Header', $header->get('Subject')) .
        "Date: ".$header->get('Date') . "\n";

    print FILE encode('iso-8859-1', $headertxt);
    print FILE $body;

    close FILE;

    if (defined($status)) {
        open FILE, "> $logfile" || die "can't create $logfile";
        print FILE $status;
        close FILE;
        $curseries_nbad++;
    } else {
        # Remember that we did output a real patch
        $patches_written++;
    }
    $curseries_length++;
}

# Finish up the series, move on to the next one
sub output_series_done
{
    # If all of the messages in the series are bad, create a final .log file right now
    if ($curseries_nbad == $curseries_length) {
        # FIXME: create a real log file by pulling in the individual .logs
        open FILE, "> tmp.$curseries/log.txt" || die "can't open tmp.$curseries/log.txt\n";
        print FILE "Some patch was malformed, see individual patch logs.\n";
        close FILE;
    }
    rename("tmp.$curseries", "$curseries") || die "can't rename tmp.$curseries to $curseries\n";
    $curseries++;
}

# Write a series consisting of a single message to disk.
sub output_standalone_message
{
    my $header = $_[0];
    my $body = $_[1];
    my $status = $_[2];
    output_series_start();
    output_message($header, $body, $status, 1);
    output_series_done();
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

    if ($series_sender ne $sender || $series_num_patches != $num_patches) {
        print "Not part of current series (wanted $series_sender, $series_num_patches), deferring; sender $sender, num_patches $num_patches, subject ".$header->get('Subject')."\n";
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
        output_series_start();
        for ($j=1; $j <= $series_num_patches; $j++) {
            #print "Outputting patch $j of $series_num_patches\n";
            output_series($series_headers[$j], $series_bodies[$j], undef, $j);
            $pop->Delete( $series_indices[$j] );
        }
        output_series_done();
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
        output_standalone_message($header, $body, undef);
        $pop->Delete( $index );
    } else {
        # part of sequence 
        my $which_patch = $1;
        my $num_patches = $2;
        if ($which_patch == 0) {
            # Zeroth patch in series is supposed to be just explanation?
            output_standalone_message($header, $body, "patch zero of a series");
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

    if ($subject =~ /FOLDER INTERNAL DATA/) {
        print "Ignoring webmail marker: $subject\n";
        $pop->Delete( $i );
        next;
    }

    # Delete messages without body?
    if (!defined($body)) {
        output_standalone_message($head, $body, "No body");
        print "no body: $subject\n";
        $pop->Delete( $i );
        next;
    }

    if ($numpatches_in_msg == 0) {
        output_standalone_message($head, $body, "No patch detected");
        print "No patch: $curseries, $from, $subject\n";
        $pop->Delete( $i );
        next;
    }

    if ($numpatches_in_msg > 1) {
        output_standalone_message($head, $body, "Multiple patches detected, ignoring");
        print "Multiple patches in one message not allowed (this is a wine-patches policy): $subject\n";
        $pop->Delete( $i );
        next;
    }

    # TODO: delete patches older than three days
    my $date = $head->get('Date');
    my $parsedDate = ParseDate($date);
    my $dateDelta = DateCalc($parsedDate, ParseDate("today"));
    my $ageHours = Delta_Format($dateDelta, 0, "%ht");
    if ($ageHours > 48) {
        print "Deleting stale message: subj $subject, date $date, ageHourse $ageHours\n";
        output_standalone_message($head, $body, "Stale message (could be patchwatcher bug), ignoring");
        $pop->Delete( $i );
        next;
    }
 
    consume_patch($head, $body, $i);
}
$pop->Close();

if ($patches_written > 0) {
    exit(0);
} else {
    exit(1);
}

