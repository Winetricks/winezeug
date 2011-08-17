#!/usr/bin/perl
# Find patches to try.
# Output ids to stdout.  Each line is one patch series.
# Outputs at most $maxpatches lines, tries to output only $maxpatches patches.
# Remember already-output patches in parsepatches_done.dat, and don't output them again.
#
# Retrieves http://source.winehq.org/patches/
# Parses lines of the form
# <tr class="even nil"><td class="id">77511</td><td class="status"><a href="#legend">New</a></td><td class="author">Joerg-Cyril.Hoehle@t-systems.com</td><td class="subject"><a href="data/77511">kernel32/tests: WaitForMultipleObjects returns lowest signaled handle first. (without space)</a></td><td class="test bot">OK</td></tr>
# Ignore lines which have status != New or test bot status == Failed

if (@ARGV != 1) {
    die "Usage: perl parsepatches.pl maxpatches\nPrints ids of maxpatches new patch series from source.winehq.org/patches, saves history in parsepatches_done.dat\n";
}

$maxpatches=$ARGV[0];
# Ignore patches this far down in the queue and lower
# This needs to be as big as the biggest expected patch series
$maxage=15;

if (-f "parsepatches_done.dat") {
    open(DONE, "parsepatches_done.dat");
    while (<DONE>) {
        chomp;
        $done_ids{$_}++;
    }
    close(DONE);
}

open(PIPE, "wget -O- http://source.winehq.org/patches/|") || die "can't fetch patch status";
#open(PIPE, "index.html");
while (<PIPE>) {
    s/&#39;/'/g;
    if (m,<tr class=".* nil"><td class="id">(\d*)</td><td class="status"><a href="#legend">New</a></td><td class="author">([^<]*)</td><td class="subject"><a href="data/\d*">(.*)</a></td><td class="testbot">(\S*)</td></tr>,) {
        $id=$1;
        $author=$2;
        $subject=$3;
        $testbotstatus=$4;
        $author =~ s/\s*$//;
        # Don't consider really old patches
        if ($numpatches++ > $maxage) {
            last;
        }
        if ($testbotstatus eq "Failed") {
            next;
        }
        if (m,\[\D*(\d+)/(\d+)\D*\],) {
            $num = $1;
            $len = $2;
            if ($num > 0 && $num <= $len) {
                #print "id $id, author $author, num/len $num / $len: $subject\n";
                push(@series, "${author}\|${len}\|${num}\|${id}\|${subject}");
            #} else {
            #    print "id $id, author $author, bad sequence num/len $num / $len: $subject\n";
            }
        } elsif (!$done_ids{$id}) {
            $doing_ids{$id}++;
        }
    }
}
close(PIPE);

# Detect patch series.
# FIXME: Right now, nearby series of same length from same author are ignored, e.g.
# [PATCH 1/2] dxdiagn: COM cleanup for the IDxDiagProvider iface.
# [PATCH 2/2] dxdiagn: COM cleanup for the IDxDiagContainer iface.
# [PATCH 1/2] amstream: COM cleanup for the IMediaStreamFilter iface.
# [PATCH 2/2] amstream: Avoid a forward declaration of the IMediaStreamFilter vtbl.

foreach (sort(@series)) {
    /(.*)\|(.*)\|(.*)\|(.*)\|(.*)/ || die;
    $author=$1; $len=$2; $num=$3; $id=$4; $subject=$5;
    $authorlen = $author.$len;
    if ($num == 1) {
        # start series
	$series = $id;
    } elsif ($authorlen eq $oldauthorlen) {
        if ($num == $oldnum + 1 && abs($id - $oldid) < 2 * $len) {
            $series .= " $id";
            if ($num == $len) {
                if (!$done_ids{$id}) {
                    $doing_ids{$series}++;
                }
            }
        }
    } else {
        $num = 0;
        $series = "";
    }
    $oldauthorlen = $authorlen;
    $oldnum = $num;
    $oldid = $id;
}

$n = 0;
foreach(sort {$b - $a} (keys(%doing_ids))) {
    last if ($n >= $maxpatches);
    print "$_\n";
    foreach(split(" ")) {
	$done_ids{$_}++;
        $n++;
    }
}
open(DAT, "> parsepatches_done.dat") || die;
foreach(sort(keys(%done_ids))) {
    print DAT "$_\n";
}
close(DAT);
