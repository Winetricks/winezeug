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

my $i;
for ($i = 1; $i <= $pop->Count(); $i++) {
   my $msg;
   $msg = $pop->HeadAndBody( $i );
   my $entity = $parser->parse_data($msg);

   $entity->make_singlepart;

   if ($entity->parts < 2) {
        if ($entity->bodyhandle->as_string =~ m/diff/) {
            if ($entity->head->get('Subject') !~ /\d\/\d/) {
                output_patch($entity->head, $entity->bodyhandle->as_string);
                #$pop->Delete( $i );
            } else {
                # part of sequence 
                # For now, just ignore; we'll deal with them later
                #$pop->Delete( $i );
                print "ignoring series". $entity->head->get('Subject')
            }
        }
   } else {
        foreach ($entity->parts) {
            if ($_->bodyhandle->as_string =~ m/diff/) {
                if ($entity->head->get('Subject') !~ /\d\/\d/) {
                    output_patch($entity->head, $_->bodyhandle->as_string);
                    #$pop->Delete( $i );
                } else {
                    # part of sequence 
                    # For now, just ignore; we'll deal with them later
                    #$pop->Delete( $i );
                    print "ignoring series". $entity->head->get('Subject')
                }
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

