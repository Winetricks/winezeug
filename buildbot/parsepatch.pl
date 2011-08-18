#!/usr/bin/perl
# Retrieves patches from http://source.winehq.org/patches/data/*
# Collates them into patch series, then outputs $maxpatches lines,
# one per patch series; each line contains patch ids separated by whitespace.
# Remembers already-output patches in parsepatches_done.dat, and doesn't output them again.
#
# Because we can't do a good enough job identifying patch series from
# just the info in the index, and patches may need to be scanned many times,
# we mirror all patches locally.
#
# Here's how it identifies patch series.
# For each author:
#   Sort patches by the first Date: line in each patch
#   Scan from oldest to newest, parsing [%d/%d], looking for an unbroken series
# Outputs most recent patch series first.

use DateTime::Format::Mail;

if (@ARGV != 1) {
    die "Usage: perl parsepatches.pl maxpatches\nPrints ids of maxpatches new patch series from source.winehq.org/patches, saves history in parsepatches_done.dat\n";
}

$maxpatches=$ARGV[0];
# Ignore patches this far down in the queue and lower
# This needs to be as big as the biggest expected patch series
$maxage=100;

$verbose = 0;

sub update_cache() {
    my $last_id;
    if (-f "parsepatches_last.dat") {
        open(LAST, "parsepatches_last.dat");
        $last_id = <LAST>;
        chomp $last_id;
        close(LAST);
    } else {
        $last_id = 77450;
    }
    # Update our cache of patches
    mkdir("cached_patches");
    for (;;) {
        $last_id++;
        print "Fetching patch $last_id\n" if ($verbose > 1);
        if (system("wget -O cached_patches/cache-$last_id.patch http://source.winehq.org/patches/data/$last_id > /dev/null 2>&1")) {
            unlink("cached_patches/cache-$last_id.patch");
            $last_id--;
            last;
        }
        sleep 1;
    }
    open(LAST, "> parsepatches_last.dat") || die;
    print LAST "$last_id\n";
    close(LAST);
}

# Compare two patches by their first Date: field
sub bydate() {
    my $parser = DateTime::Format::Mail->new();
    $parser->loose();

    my @x, $date;
    @x = grep(/^Date:/, @$a);
    $date = $x[0];
    $date =~ s/^Date: //;
    my $datetime_a = $parser->parse_datetime($date);

    @x = grep(/^Date:/, @$b);
    $date = $x[0];
    $date =~ s/^Date: //;
    my $datetime_b = $parser->parse_datetime($date);
    return $datetime_a <=> $datetime_b;
}

#---------- Main program ---------------

update_cache();

if (-f "parsepatches_done.dat") {
    open(DONE, "parsepatches_done.dat");
    while (<DONE>) {
        chomp;
        $done_ids{$_}++;
    }
    close(DONE);
}

# Read in each patch, figure out the sender, append it to an array of that sender's patches
# Result is saved in %patches_by_author
my %patches_by_author;
foreach (<cached_patches/cache-*.patch>) {
    # Skip it if we've already processed it (really, we could delete the file from the cache instead)
    /.*cache-(\d+).patch/ || die;
    $patch_id = $1;
    next if $done_ids{$patch_id};
    # Skip it if it's too old
    next if $last_id - $patch_id > $maxage;

    open(PATCH, $_) || die;
    my @patch;
    push(@patch, "testbotId: $patch_id");
    push(@patch, grep(chomp, <PATCH>));
    close PATCH;
    @x = grep(/^From:/, @patch);
    $from = $x[0];
    $from =~ s/^From: //;

    if (!defined $patches_by_author{$from}) {
        $patches_by_author{$from} = [];
    }
    $ref_patches_by_this_user = $patches_by_author{$from};
    push(@$ref_patches_by_this_user, \@patch);
}

# Consider each author's patches in the order sent
foreach $from (sort(keys(%patches_by_author))) {
    $ref_patches_by_this_user = $patches_by_author{$from};
    $oldnum = 0;
    $series = "";
    foreach (sort bydate @$ref_patches_by_this_user) {
        @x = grep(/^Date:/, @$_);
        $date = $x[0];
        $date =~ s/^Date: //;
        @x = grep(/^Subject:/, @$_);
        $subject = $x[0];
        $subject =~ s/^Subject: //;
        @x = grep(/^testbotId:/, @$_);
        $patch_id = $x[0];
        $patch_id =~ s/^testbotId: //;
        print "Considering id $patch_id, date $date, author $from, subject $subject\n" if ($verbose > 1);
        if ($subject =~ m,\[\D*(\d+)/(\d+)\D*\],) {
            $num = $1;
            $len = $2;
            if ($num > 0 && $num <= $len) {
                if ($num == 1) {
                    $oldnum = $num;
                    $series = $patch_id;
                } elsif ($num == $oldnum + 1) {
                    $series .= " $patch_id";
                    if ($num == $len) {
                        print "ids $series, date $date, author $from, subject $subject\n" if ($verbose);
                        push(@result, "$series\n");
                        $oldnum = 0;
                    } else {
                        $oldnum = $num;
                    }
                } else {
                    $oldnum = 0;
                }
            }
        } else {
            print "id $patch_id, date $date, author $from, subject $subject\n" if ($verbose);
            push(@result, "$patch_id\n");
        }
    }
}

# Sort numerically, highest first
@result = sort {$b - $a} @result;

# Output the most recent $maxpatches patch series
for ($i=0; $i < $maxpatches; $i++) {
    print $result[$i];
    $done_ids{$result[$i]}++;
}

# Remember which patches we've output
open(DAT, "> parsepatches_done.dat") || die;
foreach(sort(keys(%done_ids))) {
    print DAT "$_\n";
}
close(DAT);
