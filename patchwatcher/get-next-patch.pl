#!/usr/bin/perl
# Retrieve next patch from the specified mailbox, delete it
# Also delete any non-patch email encountered
# Dan Kegel 2008

# TODO: sort patch series and output them when complete in proper order

use strict;
use warnings;
use Mail::POP3Client;
use MIME::Parser;

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

# Read in all patches, assign them to patch groups,
# output all complete patch groups.
# Argument is number of first patch to output.
# Patches are output as %d.patch.

my $curpatch = $ARGV[0];
if ($curpatch eq "") {
    print "Usage: perl get-patches.pl starting-patch-number\n";
    exit(1);
}

my $patches_written = 0;

sub output_patch
{
    my $header = $_[0];
    my $body = $_[1];
    open FILE, "> $curpatch.patch" || die "can't create $curpatch.patch";
    $curpatch++;
    $patches_written++;

    print FILE "From: ".$header->get('From');
    print FILE "Subject: ".$header->get('Subject');
    print FILE "Date: ".$header->get('Date');
    print FILE "\n";
    print FILE $body;

    close FILE;
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

    my $sender = $header->get('From');

    if ($series_sender eq "") {
       print "Starting series; sender $sender, num_patches $num_patches, subject ".$header->get('Subject')."\n";
       $series_sender = $sender;
       $series_num_patches = $num_patches;
    }

    if ($series_sender ne $sender) {
       print "Ignoring series for now, will try later; sender $sender, num_patches $num_patches, subject ".$header->get('Subject')."\n";
        # can't handle multiple series at once just yet, let it sit
        return;
    }
    print "Saving patch $which_patch\n";
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
            print "Outputting patch $j of $series_num_patches\n";
            output_patch($series_headers[$j], $series_bodies[$j]);
            #$pop->Delete( $series_indices[$j] );
        }
        @series_headers = ();
        @series_bodies = ();
        @series_indices = ();
        $series_sender = "";
        $series_num_patches = "";
    }
}

# Return true if patch detected
# Delete message unless it's a patch we can't consume just yet
sub consume_message
{
    my $header = $_[0];
    my $body = $_[1];
    my $index = $_[2];

    if ($body =~ m/diff/) {
        if ($header->get('Subject') !~ /(\d+)\/(\d+)/) {
            output_patch($header, $body);
            #$pop->Delete( $index );
        } else {
            # part of sequence 
            my $which_patch = $1;
            my $num_patches = $2;
            if ($which_patch == 0) {
                # Zeroth patch in series is supposed to be just explanation?
                #$pop->Delete( $index );
            } else {
                consume_series_patch($header, $body, $index, $which_patch, $num_patches);
            }
        }
        return 1;
    } else {
        #$pop->Delete( $index );
    }
    return 0;
}

my $i;
for ($i = 1; $i <= $pop->Count(); $i++) {
   my $msg;
   $msg = $pop->HeadAndBody( $i );
   my $entity = $parser->parse_data($msg);

   $entity->make_singlepart;

   if ($entity->parts < 2) {
        consume_message($entity->head, $entity->bodyhandle->as_string, $i);
   } else {
        foreach ($entity->parts) {
            if (consume_message($entity->head, $_->bodyhandle->as_string, $i)) {
                last;
            }
        }
   }
}
$pop->Close();

if ($patches_written > 0) {
    exit(0);
} else {
    exit(1);
}

