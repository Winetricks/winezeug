#!/usr/bin/perl
# 
# Script to look for MS DLLs and imports of symbols from them which Wine does not yet have an implementation
# Copyright 2010 Dan Kegel
# LGPL

# Usage: perl mscodescan.pl [-l][-q]
# -l: just list dlls/exe's, not missing imports
# -q: don't output titles

my %opt;
#use Getopt::Std;
#getopt("lq", %opt);   doesn't work?
foreach (@ARGV) {
    if ($_ eq '-l') {
        $opt{'l'} = 1;
    } elsif ($_ eq '-q') {
        $opt{'q'} = 1;
    } else {
        die("unknown option $_\n");
    }
}

$winesrc = $ENV{"HOME"}."/wine-git";

# Create list of known MS dlls
# Get list of fake DLLs.  Assumes you've initialized .wine.  
# (It'd be better to look at wine.inf, but that looks hard?)
@needles = split("\n", `grep -l "Wine placeholder DLL" ~/.wine/drive_c/windows/system32/*.dll | grep -iv OpenAL32 | sed 's,.*/,,;s/\\.dll\$//'`);
# MS DLLs for which we don't have fake DLLs
push(@needles, 
   "atl70",
   "atl80",
   "atl90",
   "drmstor",
   "drmv2clt",
   "dxmasf",
   "ieaksie",
   "iepeers",
   "iesetup",
   "mfc42",
   "mfc70",
   "mfc80",
   "mfc90",
   "mshtmled",
   "mshtmler",
   "msident",
   "msidntld",
   "msieftp",
   "msoe",
   "msscp",
   "mstime",
   "msvcm70",
   "msvcm71",
   "msvcm80",
   "msvcm90",
   "msvcp70",
   "msvcp71",
   "msvcp80",
   "msvcp90",
   "msvcr70",
   "msvcr71",
   "msvcr80",
   "msvcr90",
   "msxml3a",
   "msxml3r",
   "rpclts5",
   "rpcltscm",
   "rpcltspx",
   "rpcns4",
   "webcheck",
   "wmidx",
   "wmpshell",
   "wmsdmod",
   "wmsdmoe2",
   "wmvcore",
   "wshext",
);
# Avoid dups
@needles = grep !$seen{$_}++, @needles;

# Stoplist of functions we don't care about (because they're only called when app crashes)
# See also http://bugs.winehq.org/show_bug.cgi?id=22044#c4
# Note: strings with @'s need to be single-quoted in perl, it seems
%stoplist = (
   '?_type_info_dtor_internal_method@type_info@@QAEXXZ' => 1,
   "__clean_type_info_names_internal" => 1,
   "_crt_debugger_hook" => 1,
   "_except_handler4_common" => 1,
   "_invoke_watson" => 1,
);

foreach $needle (@needles) {
    $file = "$winesrc/dlls/$needle/$needle.spec";
    if (open(FILE, $file)) {
        foreach $line (grep(/stub/, <FILE>)) {
           chomp($line);
           # this is messy
           foreach $stub (split(" ", $line)) {
               if ($stub !~ /-arch=win/ && !$stoplist{$stub}) {
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
#print "Executing $command\n";
open(NAMES, "$command |") || die;
@haystacks = <NAMES>;
close(NAMES);
chomp(@haystacks);

#print "Got haystacks ";
#print join("\n", @haystacks);

# Look for Microsoft DLLs and EXEs - we don't care what *they* import
foreach $haystack (@haystacks) {
    $found = 0;
    if ($haystack =~ m,\b(winsxs|Microsoft.NET|assembly/GAC_32|system32/update/update.exe|system32/spuninst.exe)\b,) {
       $found = 1;
    } else {
        foreach $needle (@needles) {
            if ($haystack =~ /\b$needle.dll/i) {
               $found = 1;
               break;
            }
        }
    }
    # Some games (e.g. second life) ship dlls with same name as microsoft ones, 
    # so don't call it a microsoft dll unless it contains the string "microsoft corp"
    if ($found) {
	# Note extra backslash in escaped NULL!
        open(PIPE, "tr -d '\\000' < '$haystack' | grep -il 'microsoft corp' |") || die;
	$x = <PIPE>;
	close(PIPE);
	if (length($x) < 4) {
	    print "File $haystack does not contain magic string 'microsoft corp', so assuming not a real Microsoft file.\n";
	    $found = 0;
	}
    }
    if ($found) {
       push(@bundled, $haystack);
    } else {
       push(@nonbundled, $haystack);
    }
}

if (@bundled) {
    if (! $opt{'q'}) {
        print "Found ".scalar(@bundled)." bundled MS modules:\n";
    }
    foreach $haystack (@bundled) {
        print "  " if (! $opt{'l'});
	print "$haystack\n";
    }
}
if ($opt{'l'}) {
    exit(0);
}

print "\n";

foreach $haystack (@nonbundled) {
    chomp $haystack;
    $escaped_haystack = $haystack;
    $escaped_haystack =~ s/'/'\\''/;
    $command = "winedump -j import '$escaped_haystack'";
    open(FILE, "$command |") || die "running command $command\n";
    $imports{$haystack} = join("", <FILE>);
    close FILE;
}

#print "Imports:\n";
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
            print "\n\n";
	}
    }
}
