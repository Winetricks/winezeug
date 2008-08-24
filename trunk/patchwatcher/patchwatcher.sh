#!/bin/sh
# Simple continuous build for Wine 
# Copyright 2008 Google (Dan Kegel)
# License: LGPL
#
# Watches the wine-patches mailing list, builds incoming patches against
# current git, runs conformance tests.  
# Results sent out via email and uploaded to a web site.

# Warning:
# This script executes source code sent in by anonymous users,
# and is therefore very dangerous.  Run this in as isolated
# and low-privilege environment as possible.
# The ftp account you upload results to should also have as 
# few permissions as possible, and should not be able to write
# anything interesting.
# TODO: merge chroot code, e.g. Ambroz's, see
# http://www.winehq.org/pipermail/wine-devel/2008-August/068037.html

# Prerequisites:
# Must do
#    sudo apt-get install libmail-pop3client-perl 
#    sudo apt-get install libmime-perl
#    sudo apt-get install mailx
# and make sure mailx can send mail before running first time.
# (You may need to do sudo dpkg-reconfigure exim4-config.)
#
# Must set environment vars to point to a mailbox subscribed to wine-patches
#   PATCHWATCHER_USER=user@host.com
#   PATCHWATCHER_HOST=mail.host.com
#   PATCHWATCHER_PASSWORD=userpass 
# before running.  
# All messages will slowly be deleted from the mailbox as this script runs.

# Must set envionment vars to point to an ftp account:
#   PATCHWATCHER_FTP=ftp.host.com
# This script assumes that you have configured ftp (perhaps via ~/.netrc)
# with the username and password to allow the script to upload to the
# results directory at $PATCHWATCHER_FTP via ftp.

# Must set env vars to point to the web page results will appear:
#   PATCHWATCHER_URL=http://www.host.com/patchwatcher/results
# This should refer to the same directory as $PATCHWATCHER_FTP/results.

# This script configures and builds wine in a directory called 'active'.
# Then whenever it wants to try a new patch, it moves that directory
# aside and replaces it with a copy.
# When it's done trying out the patch, it deletes the copy and moves
# the real directory back where it was.
# All this fancy dancing is just to avoid irritating anything
# that depends on absolute paths being the same as when 'configure' was run.
# The copies sound slow but they only take a few seconds on a 
# modern machine.

set -e
set -x

# Set this to true on first run and after debugging
initialize=false
# Set this to true for continuous build
loop=true

# Regular expression matching known flaky tests
# This list is built up by simply running patchwatcher for a while and
# seeing what tests cause spurious failure reports.
# Annoyingly, no matter how many times I run the baseline tests,
# these buggers still manage to fail in new ways when testing patches.
# Grumble.
blacklist_regex="comctl32:tooltips.c|d3d9:device.c|d3d9:visual.c|ddraw:visual.c|kernel32:thread.c|urlmon:protocol.c|urlmon:url.c|user32:msg.c|user32:input.c|user32:monitor.c|wininet:http.c"

TOP=`pwd`
PATCHES=$TOP/patches
WORK=$TOP/wine-continuous-workdir
if $initialize
then
    rm -rf $WORK
    mkdir -p $WORK
else
    # Recover from run aborted with ^C
    if test -d $WORK/golden
    then
        rm -rf $WORK/active
        mv $WORK/golden $WORK/active
    fi
fi
mkdir -p $PATCHES/mimemail

WINE=$WORK/active/wine
WINESERVER=$WORK/active/server/wineserver
WINEPREFIX=$HOME/.wine
# export so we can invoke winetricks
export WINE WINEPREFIX

baseline_tests()
{
    # Gather list of tests that fail at least once in N runs
    # Once this script is debugged, crank up the number of runs a bit here
    cd $WORK/active
    for try in 1 2 3 4 5
    do
        make testclean
        $WINESERVER -k || true
        rm -rf $WINEPREFIX || true
        sh $TOP/../winetricks gecko
        make -k test || true
    done > flaky.log 2>&1

    perl $TOP/get-dll.pl < flaky.log | egrep ": Test failed: |: Test succeeded inside todo block: " | sort -u | egrep -v $blacklist_regex > flaky.dat || true
    # Record for posterity
    cp flaky.log $PATCHES/baseline.testlog
    cp flaky.dat $PATCHES/baseline.testdat
}

initialize_tree()
{
    cd $WORK
    git clone git://source.winehq.org/git/wine.git active
    cd active
    ./configure
    make depend
    make -j3

    baseline_tests
}

refresh_tree()
{
    cd $WORK/active
    # Recover from any accidental damage
    git diff > git.diff && patch -R -p1 < git.diff
    # Grab latest source
    git pull > git.log 2>&1
    cat git.log
    if ! grep -q "Already up-to-date." < git.log
    then
       time make -j3
       baseline_tests
    fi
}

retrieve_patches()
{
    cd $PATCHES
    LAST=`ls *.txt | sort -n | tail -1 | sed 's/\.txt$//'`
    NEXT=`expr $LAST + 1`
    perl $TOP/get-patches.pl $NEXT || true
    # Handle immediate results
    while test -f $NEXT.log
    do
        report_results patch $NEXT.txt  $NEXT.log
        NEXT=`expr $NEXT + 1`
    done
}

# Usage: report_results build|make|test|success patch log
report_results()
{
    status=$1
    patch=$2
    log=$3

    cd $PATCHES

    # Retrieve sender and subject from patch file
    # Patch file is written by get-patches.pl in a specific format,
    # always starts with an email header.
    patch_sender="`cat $patch | grep '^From:' | sed 's/^From: //;s/.*<//;s/>.*//'`"
    patch_subject="`cat $patch | grep '^Subject:' | sed 's/^Subject: //'`"
    case $status in
    patch)   status_long="failed to apply" ;;
    build)   status_long="failed to build" ;;
    test)    status_long="failed regression tests" ;;
    success) status_long="applied, built, and passed tests" ;;
    esac

    cat - > msg.dat <<_EOF_
Hi!  This is the experimental automated wine patchwatcher thingy.
The latest git sources were built and tested with your patch
"$patch_subject"
Result: the patch $status_long.

You can retrieve the full build results at
  $PATCHWATCHER_URL/$log
and see the patch as parsed at
  $PATCHWATCHER_URL/$patch
See
  $PATCHWATCHER_URL
for more info.

_EOF_

    # don't email on success, too noisy
    case $status in
    success) ;;
    *) mailx -s "Patchwatcher: ${status_long}: $patch_subject" "$patch_sender" dank@kegel.com  < msg.dat
    ;;
    esac
    rm msg.dat

    perl $TOP/dashboard.pl > index.html
    ftp $PATCHWATCHER_FTP <<_EOF_
cd results
put $patch 
put $log
put index.html
quit
_EOF_
}

# Return true if a patch was tried, false if no patches left to try
try_one_patch()
{
    cd $PATCHES

    # Find first patch that doesn't have a .log
    NEXT=""
    for p in `ls *.txt *.log | sort -n | sed 's/\..*//' | sort -n | uniq -c | awk '$1 == 1 {print $2}'`
    do
        if test -f $p.txt
        then
           NEXT=$p
           break
        fi
    done
 
    if test -z "$NEXT"
    then
        echo No patch to apply
        return 1
    fi

    cd $WORK
    rm -rf golden
    mv active golden
    cp -a golden active

    # Do one patch (or patch series).
    # This loop assumes that get-patches.pl never outputs incomplete patch series
    while true
    do
        echo Processing patch $NEXT.txt:
        cat $PATCHES/$NEXT.txt

        cd $WORK/active
        # Should we use -p1 or -p0?
        # CVS patches need -p0, git patches need -p1
        # For now, always use -p0 unless it's obvious patch was
        # generated with cvs or svn
        if egrep -q 'RCS file|^+++.*working copy' < $PATCHES/$NEXT.txt
        then
            p=0
        else
            p=1
        fi

        if ! patch -p$p < $PATCHES/$NEXT.txt > $PATCHES/$NEXT.log 2>&1
        then
           report_results patch $NEXT.txt  $NEXT.log
        else
           # TODO: need to run configure?
           # Note: don't use parallel build, we want to email a nice clean log
           if ! make 2>&1 | perl $TOP/trim-build-log.pl >> $PATCHES/$NEXT.log || ! grep "^Wine build complete" $PATCHES/$NEXT.log 
           then
               report_results build $NEXT.txt  $NEXT.log
           else
               make testclean
               $WINESERVER -k || true
               rm -rf $WINEPREFIX || true
               sh $TOP/../winetricks gecko
               time make -k test > $PATCHES/$NEXT.testlog 2>&1 || true
               perl $TOP/get-dll.pl < $PATCHES/$NEXT.testlog | egrep ": Test failed: |: Test succeeded inside todo block: " | sort -u | egrep -v $blacklist_regex > $PATCHES/$NEXT.testdat || true
               cat $PATCHES/$NEXT.testlog >> $PATCHES/$NEXT.log
               echo "Regression test changes vs. baseline test runs:" >> $PATCHES/$NEXT.log
               diff flaky.dat $PATCHES/$NEXT.testdat >> $PATCHES/$NEXT.log || true
               # Report failure if any new errors
               diff flaky.dat $PATCHES/$NEXT.testdat > $PATCHES/$NEXT.testdiff || true
               if grep -q '^> ' < $PATCHES/$NEXT.testdiff
               then
                   echo "Ditto, but just the new errors:" >> $PATCHES/$NEXT.log
                   grep '^> ' < $PATCHES/$NEXT.testdiff | sed 's/^>//' >> $PATCHES/$NEXT.log || true
                   report_results test $NEXT.txt  $NEXT.log
               else
                   echo "Conformance tests ok" >> $PATCHES/$NEXT.log
                   report_results success $NEXT.txt  $NEXT.log
               fi
           fi
           cat $PATCHES/$NEXT.log
        fi
        # Use a regexp with a back reference to detect last patch in a series and break out
        if egrep -q 'Subject:.*[0-9]+/[0-9]+' $PATCHES/$NEXT.txt && ! egrep -q 'Subject:.*([0-9]+)/\1[^0-9]' $PATCHES/$NEXT.txt
        then
            echo In middle of patch series, not wiping tree
            NEXT=`expr $NEXT + 1`
        else
            break
        fi
    done

    cd $WORK
    rm -rf active
    mv golden active
    return 0
}

continuous_build()
{
  while true
  do
     date
     refresh_tree
     retrieve_patches
     while try_one_patch
     do
         sleep 1
         $loop || break
     done
     sleep 60
     $loop || break
  done
}

if $initialize
then
    initialize_tree
else
    retrieve_patches
    cd $PATCHES
    perl $TOP/dashboard.pl > index.html
    ftp $PATCHWATCHER_FTP <<_EOF_
cd results
prompt
mput *.txt
mput *.log
put index.html
quit
_EOF_
fi
continuous_build
