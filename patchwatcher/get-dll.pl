#!/usr/bin/perl
my $dll;
while (<STDIN>) {
    if (/make...: Entering directory ..*\/dlls\/(.*)\/tests/) {
       $dll=$1;
    } elsif (/make.*Leaving directory/) {
       undef $dll;
    }
    if (/: Test failed: |: Test succeeded inside todo block: /) {
        if (defined($dll)) {
            print "$dll:$_";
        } else {
            print ;
        }
    }
}

