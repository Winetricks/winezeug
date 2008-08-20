#!/usr/bin/perl
# Copyright 2007-2008 Google (Dan Kegel) for Wine
# LGPL
#
# To detect new valgrind warnings in the output of wine's make test,
# one would like to diff the logs, but this is hard because
# Valgrind warnings are multiple lines long.
# This script partially solves that problem by
# adding a one-line warning signature of the form
# ### dlls/foo/tests/bar.ok warningType fn1_file1-fn2_file2-fn3_file3
# after each valgrind warning.  
#
# The first field is the target to make to reproduce the warning.
# The second field is the valgrind warning type (code, mismatch, etc.)
# The third field is an abbreviated stack dump showing where the
# warning occurred, minus line numbers.
#
# The warning signatures do not have as much information as
# the original valgrind warnings, but they are still useful
# for finding regressions.
#
# If changing the wine tree produces new warning signatures,
# there are three possibilities:
# 1) the tests are flaky, and only show some warning intermittantly;
# 2) the new wine tree has a new bug,
# 3) the new wine tree has a stricter test that exposes a latent bug.
# The developer can repeat the warning by running the test 
# indicated in the first column under valgrind.

# Example:
# The output of "RUNTEST_WRAPPER=valgrind make -j2 -k test" looks like this:
# ...
# ../../../tools/runtest -q -P wine -M dll0.dll -T ../../.. -p dll0_test.exe.so file0.c
# ...
# ==30429== Conditional jump or move depends on uninitialised value(s)
# ==30429==    at 0x51454B7: fn1 (file1.c:527)
# ==30429==    by 0x5145671: fn2 (file2.c:568)
# ==30429==    by 0x5145798: fn3 (file3.c:606)
# ==30429==    by 0x5146ED1: fn4 (file4.c:933)
# ...
# ==30429==  Uninitialised value was created by a stack allocation
# ==30429==    at 0x58B997F: fnx (filex.c:6835)
# ...
# ==30429== Conditional jump or move depends on uninitialised value(s)
# ==30429==    at 0x51454B7: fna (filea.c:527)
# ==30429==    by 0x5145671: fnb (fileb.c:568)
# ==30429==    by 0x5145798: fnc (filec.c:606)
# ==30429==    by 0x5146ED1: fnd (filed.c:933)
# ...
# ==30429==  Uninitialised value was created by a stack allocation
# ==30429==    at 0x58B997F: fny (filey.c:6835)
# ...
#
# where the culprit section at the end is not present for all kinds of warnings.
#
# We want to output them in the same form, but with one extra
# line after each warning, e.g.
#
# ../../../tools/runtest -q -P wine -M dll0.dll -T ../../.. -p dll0_test.exe.so file0.c
# ...
# ==30429== Conditional jump or move depends on uninitialised value(s)
# ==30429==    at 0x51454B7: fn1 (file1.c:527)
# ==30429==    by 0x5145671: fn2 (file2.c:568)
# ==30429==    by 0x5145798: fn3 (file3.c:606)
# ==30429==    by 0x5146ED1: fn4 (file4.c:933)
# ...
# ==30429==  Uninitialised value was created by a stack allocation
# ==30429==    at 0x58B997F: fnx (filex.c:6835)
# ### dll0/tests/file0.ok cond fn1_file1-fn2_file2-fn3_file3--fnx_filex
# ...
# ==30429== Conditional jump or move depends on uninitialised value(s)
# ==30429==    at 0x51454B7: fna (filea.c:527)
# ==30429==    by 0x5145671: fnb (fileb.c:568)
# ==30429==    by 0x5145798: fnc (filec.c:606)
# ==30429==    by 0x5146ED1: fnd (filed.c:933)
# ...
# ==30429==  Uninitialised value was created by a stack allocation
# ==30429==    at 0x58B997F: fny (filey.c:6835)
# ==30429==    at 0x58B997F: fnz (fileyzc:6000)
# ...
# ### dll0/tests/file0.ok cond fna_filea-fnb_fileb-fnc_filec

my($desired_frame_count) = 3;

# Return abbreviated warning type, or empty string if current line isn't the start of a warning
sub is_first_line_of_warning
{
	/uninitialised/ && return "uninit";
        /Invalid read/ && return "read";
	/Invalid write/ && return "write";
	/Invalid free/ && return "free";
	/Source and destination overlap/ && return "overlap";
	/Mismatched free/ && return "mismatch";
	/unaddressable byte/ && return "unaddressable";
	/vex x86/ && return "vex";
	/Warning: invalid file descriptor/ && !/Warning: invalid file descriptor -1 in syscall close/ && return "fd";
	return "";
}

my($test_id) = "";
my($warning_type) = "";
my($nframes) = 0;
my($framelist) = "";

while (<>) {
        # runtest puts a # in front of commandlines when reassembling parallel logs
	s/# runtest/runtest/;
	if (/runtest.*-M (.*)\.dll.*exe\.so (.*)\.c/) {
                # Would like to handle non-dll tests sometime.
		$test_id = "dlls/$1/tests/$2.ok";
	} elsif ($warning_type ne "") {
                # Cheat - instead of really parsing the warning, just assume
                # that --generate-suppressions was turned on, and look
                # for the { after the warning.
		if (/^\{/) {
			# An warning has ended, print out its signature.
			print "### $test_id $warning_type $framelist\n";
			$warning_type = "";
		} else {
			# We're in a warning.
			if ($nframes < $desired_frame_count) {
				my($theframe) = $_;
				if ($theframe =~ m/(at|by) 0x[0-9a-fA-F]+: (\S*) \((.*)\)/) {
					$theframe = "$3:$2";
					$theframe =~ s/:\d+//;
					$framelist .= "-" if ($framelist ne "");
					$framelist .= "$theframe";
					$nframes++;
				}
			}
		}
	} else {
		$warning_type = &is_first_line_of_warning();
		if ($warning_type ne "") {
			$nframes = 0;
			$framelist = "";
		}
	}
	print;
}
