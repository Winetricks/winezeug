#!/usr/bin/perl
# 
# Script to look for MS DLLs and imports of symbols from them which Wine does not yet have an implementation
# Copyright 2010 Dan Kegel
# LGPL

# Usage: perl mscodescan.pl [-l][-q]
# -l: just list dlls/exe's, not missing imports
# -q: don't output titles
# -w: where to look for wine sources
# -i pattern: ignore wine's implementation of dlls matching pattern, report all imports

my %opt;
#use Getopt::Std;
#getopt("lq", %opt);   doesn't work?
my $pending;
$winesrc = $ENV{"HOME"}."/wine-git";

foreach (@ARGV) {
    if (defined($pending)) {
       if ($pending eq '-w') {
           $winesrc = $_ 
       } elsif ($pending eq '-i') { 
           $report_all_imports_from_these_modules = $_;
       }
       undef $pending;
    } elsif ($_ eq '-l') {
        $opt{'l'} = 1;
    } elsif ($_ eq '-q') {
        $opt{'q'} = 1;
    } elsif ($_ eq '-i') {
        $pending = $_;
    } elsif ($_ eq '-w') {
        $pending = $_;
    } else {
        die("unknown option $_\n");
    }
}
die("$pending requires argument\n") if (defined($pending));

# Caution: don't point wineprefix to the directory being tested, or you will miss lots of MS DLLs.
# Point it to a neutral, just-initialized .wine directory.
my $wineprefix = $ENV{"HOME"}."/.wine-virgin";
if (! -d $wineprefix) {
    die "Please create an empty wineprefix in $wineprefix so we can see what dummy DLLs wine has";
}
# Create list of known MS dlls
# Get list of fake DLLs.  Assumes you've initialized .wine.  
# (It'd be better to look at wine.inf, but that looks hard?)
@needles = split("\n", `grep -l "Wine placeholder DLL" $wineprefix/drive_c/windows/system32/*.dll | grep -iv OpenAL32 | sed 's,.*/,,;s/\\.dll\$//'`);

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
   "mfc40",
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
   "msvcp60",
   "msvcp70",
   "msvcp71",
   "msvcp80",
   "msvcp90",
   "msvcr70",
   "msvcr71",
   "msvcr80",
   "msvcr90",
   "msvcr100",
   "msxml3a",
   "msxml3r",
   "rpclts5",
   "rpcltscm",
   "rpcltspx",
   "rpcns4",
   "vcomp",
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

#print "Got needles ";
#print join("\n", @needles);

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

$olddir = `pwd`;
chomp $olddir;
# Look for Microsoft DLLs and EXEs - we don't care what *they* import
foreach $haystack (@haystacks) {
    chdir($olddir) || die "could not chdir to $olddir";
    $dir = $haystack;
    $file = $haystack;
    $dir =~ s!^(.*/)[^/]*$!\1!;
    $file =~ s,.*/,,;
    chdir($dir) || die "could not chdir to $dir";
    
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
        # this is lame - duplicates code from below.
        open(PIPE, "tr -d '\\000' < '$file' | strings | grep -v '<!-- Copyright 1981-2001 Microsoft Corporation -->' | egrep -i 'microsoft corp|ProductNameMicrosoft' |") || die;
        $x = <PIPE>;
        close(PIPE);
        if (length($x) > 3) {
           $found = 1;
        }
    }
    if ($found && $file =~ /cudart/i) {
        if (! $opt{'q'}) {
            print "File $haystack known to be from Nvidia, so assuming not a real Microsoft file.\n";
        }
        $found = 0;
    }
    if ($found && $file =~ /braid/i) {
        if (! $opt{'q'}) {
            print "File $haystack known to be from Number None, so assuming not a real Microsoft file.\n";
        }
        $found = 0;
    }
    if ($found && $file =~ /codwaw/i) {
        if (! $opt{'q'}) {
            print "File $haystack known to be from Activision, so assuming not a real Microsoft file.\n";
        }
        $found = 0;
    }
    if ($found && $file =~ /Battle.net/i) {
        if (! $opt{'q'}) {
            print "File $haystack known to be from Blizzard, so assuming not a real Microsoft file.\n";
        }
        $found = 0;
    }
    if ($found && $file =~ /unins000/i) {
        if (! $opt{'q'}) {
            print "File $haystack known to be Ventica uninstaller, so assuming not a real Microsoft file.\n";
        }
        $found = 0;
    }
    # Files from
    # http://connect.creativelabs.com/openal/Downloads/oalinst.zip
    # are not Microsoft, even though they include the strings
    #   Microsoft Visual C++ Runtime Library
    #   <assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
    if ($found && $file =~ /openal|wrap_oal/i) {
        if (! $opt{'q'}) {
            print "File $haystack known to be from Creative, so assuming not a real Microsoft file.\n";
        }
        $found = 0;
    }
    # Some games (e.g. second life) ship dlls with same name as microsoft ones, 
    # so don't call it a microsoft dll unless it contains the string "microsoft corp"
    # Some old pidgen.dll's, and some WMP executables, have ProductNameMicrosoft instead.
    # FIXME: remove code duplication.
    if ($found) {
	# Note extra backslash in escaped NULL!
        open(PIPE, "tr -d '\\000' < '$file' | egrep -il 'microsoft corp|ProductNameMicrosoft' |") || die;
	$x = <PIPE>;
	close(PIPE);
	if (length($x) < 4) {
            if (! $opt{'q'}) {
                print "File $haystack does not contain magic string 'microsoft corp', so assuming not a real Microsoft file.\n";
            }
	    $found = 0;
	}
    }
    if ($found) {
       push(@bundled, $haystack);
    } else {
       push(@nonbundled, $haystack);
    }
}
chdir($olddir);

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
		    $symbol = $2;
                    if ($stubs{$needle.":".$symbol} || (defined($report_all_imports_from_these_modules) && $needle =~ /${report_all_imports_from_these_modules}/)) {
                        $found{$needle.":".$symbol} = 1;
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
