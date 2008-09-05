#!/usr/bin/perl
# Script to annotate errors with the directory they occurred in
# Fragile because it uses make's human output

my $dll;
while (<>) {
    if (/make...: (Entering directory|Betrete Verzeichnis) ..*\/dlls\/(.*)\/tests/) {
       $dll=$2;
    } elsif (/make.*(Leaving directory|Verlasse Verzeichnis)/) {
       undef $dll;
    }
    if (/: Test failed: |: Test succeeded inside todo block: |^make\[.*\]: \*\*\* \[|wineserver crashed|Timeout!  Killing child/) {
        if (defined($dll)) {
            print "$dll:$_";
        } else {
            print ;
        }
    }
}

