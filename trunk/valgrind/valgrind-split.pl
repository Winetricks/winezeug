#!/usr/bin/perl
# Script to split a "RUNTEST_USE_VALGRIND=1 make -k test"
# log into one log file per test (skipping those without valgrind errors)
# Copyright 2007 Google (Dan Kegel) for Wine
# LGPL

sub is_error
{
	#return /uninitialised|Unhandled exception:|Invalid read|Warning: invalid file descriptor|blocks are definitely lost/;
	return /uninitialised|Unhandled exception:|Invalid read|Invalid write|Invalid free|Source and destination overlap|Mismatched free|unaddressable byte|Uninitialised value was created|vex x86|Warning: invalid file descriptor/ && !/Warning: invalid file descriptor -1 in syscall close/;

}

$saved = "";
$name = "";

sub flushlog
{
	if ($saved ne "") {
		$filename = "vg-$name.txt";
		open(LOG, "> $filename")|| die "can't open $filename\n";
		print "$filename\n";
		print LOG $saved;
		close LOG;
	}
	$saved = "";
	$name="$1_$2";
}

while (<>) {
        # runtest puts a # in front of commandlines when reassembling parallel logs
	s/# runtest/runtest/;

	if (/runtest.*-M (.*)\.dll.*exe\.so (.*)\.c/) {
		&flushlog();
	}
	if ($saved ne "" || &is_error()) {
		if (!/stack ptr.  To suppress/ && !/set address range perms/) {
			# Strip text which makes it harder to compare runs
			s/==.*==//;
			s/0x[0-9A-F]*://;
			s/in loss record.*//;

			# Save for later output
			$saved .= $_;
		}
	}
}
&flushlog();
