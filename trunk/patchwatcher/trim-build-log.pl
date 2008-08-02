#!/usr/bin/perl
# Trim triples of lines like this:
#make[2]: Entering directory `/home/dank/winezeug/patchwatcher/wine-continuous-workdir/active/dlls/cryptui'
#make[2]: Nothing to be done for `all'.
#make[2]: Leaving directory `/home/dank/winezeug/patchwatcher/wine-continuous-workdir/active/dlls/cryptui'


while (<STDIN>) {
    if (/make.*Entering directory/) {
       $state=$_;
    } elsif ($state ne "" && /make.*Nothing to be done for .all/) {
       # So far so good..  Keep accumulating.
       $state .= $_;
    } elsif ($state ne "" && /make.*Leaving directory/) {
       # Success.  Remove all traces of the three lines.
       $state = "";
    } else {
       # Mismatch.  Print everything.
       print $state;
       $state="";
       print $_;
    }
}
