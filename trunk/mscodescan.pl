#!/usr/bin/perl
# 
# Script to look for MS DLLs and imports of symbols from them which Wine does not yet have an implementation
# Copyright 2010 Dan Kegel
# LGPL

$winesrc = $ENV{"HOME"}."/wine-git";

# Assumes you've initialized .wine.  It'd be better to look at wine.inf, but that looks hard?
@needles = split("\n", `grep -l "Wine placeholder DLL" ~/.wine/drive_c/windows/system32/*.dll | sed 's,.*/,,;s/\\.dll\$//'`);
# Things for which we don't have stub DLLs yet
push(@needles, 
   "msvcm70",
   "msvcm80",
   "msvcm90",
   "mfc42",
   "mfc70",
   "mfc80",
   "mfc90",
);

foreach $needle (@needles) {
    $file = "$winesrc/dlls/$needle/$needle.spec";
    if (open(FILE, $file)) {
        foreach $line (grep(/stub/, <FILE>)) {
           chomp($line);
           # this is messy
           foreach $stub (split(" ", $line)) {
               if ($stub !~ /-arch=win/) {
                   $stubs{$needle.":".$stub} = 1;
               }
           }
        }
        close(FILE);
    }
}

#print "Stubs:\n";
#foreach $stub (sort(keys(%stubs))) {
#    print "$stub\n";
#}

# List all non-placeholder dlls and executables
$command = "find . \\( -iname '*.dll' -o -iname '*.exe' \\) \\! -exec grep -q 'Wine placeholder DLL' {} \\; -print | grep -v wine_gecko";
print "Executing $command\n";
open(NAMES, "$command |") || die;
@haystacks = <NAMES>;
close(NAMES);
chomp(@haystacks);

#print "Got haystacks ";
#print join("\n", @haystacks);

# remove literal needles from haystacks, report as bundled
foreach $haystack (@haystacks) {
    $found = 0;
    foreach $needle (@needles) {
        if ($haystack =~ /$needle/i) {
           $found = 1;
           break;
        }
    }
    if ($found) {
       push(@bundled, $haystack);
    } else {
       push(@nonbundled, $haystack);
    }
}


if (@bundled) {
    print "Found ".scalar(@bundled)." bundled MS modules:\n";
    foreach $haystack (@bundled) {
        print "$haystack\n";
    }
}

foreach $haystack (@nonbundled) {
    chomp $haystack;
    $escaped_haystack = $haystack;
    $escaped_haystack =~ s/'/'\\''/;
    $command = "winedump -j import '$escaped_haystack'";
    open(FILE, "$command |") || die "running command $command\n";
    $imports{$haystack} = join("", <FILE>);
    close FILE;
}

#foreach $haystack (@nonbundled) {
#    print "$haystack imports\n";
#    print $imports{$haystack};
#}

foreach $needle (@needles) {
    $found = 0;
    foreach $haystack (@nonbundled) {
        undef(%found);
        foreach (split("\n", $imports{$haystack})) {
            if ($found == 0 && /offset .* $needle/i) {
                $found = 1;
            }
            if ($found == 1 && /^\s*\d/) {
                $found = 2;
            }
            if ($found == 2) {
                if (/^\s*(\d+)\s*(\S+)\s/) {
                    if ($stubs{$needle.":".$2}) {
                        $found{$needle.":".$2} = 1;
                    }
                } else {
                    $found = 0;
                }
            }
        }
	if (keys(%found)) {
	    print "$haystack imports following stub symbols:\n  ";
            print join("\n  ", sort(keys(%found)));
            print "\n";
	}
    }
}
