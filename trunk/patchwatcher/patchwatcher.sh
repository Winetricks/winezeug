#!/bin/sh
# Simple continuous build for Wine 
# Dan Kegel 2008
#
# Watches wine-patches, builds incoming patches against
# current git, sends email out with results.

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
# before running.  All messages will slowly be deleted from the mailbox
# as this script runs.

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

initialize_tree()
{
    cd $WORK
    git clone git://source.winehq.org/git/wine.git active
    cd active
    ./configure
    make depend
    make -j3
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
       make -j3
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

# Usage: report_results build|make|success patch log
report_results()
{
    status=$1
    patch=$2
    log=$3

    cd $PATCHES

    # Retrieve sender and subject from patch file
    # Patch file is written by get-patches.pl in a specific format,
    # always starts with an email header.
    patch_sender=`cat $patch | grep '^From:' | sed 's/^From: //'`
    patch_subject=`cat $patch | grep '^Subject:' | sed 's/^Subject: //'`
    case $status in
    patch)   status_long="failed to apply" ;;
    build)   status_long="failed to build" ;;
    success) status_long="applied and built successfully" ;;
    esac

    cat - $patch $log > msg.dat <<_EOF_
Hi!  This is Dan Kegel's experimental automated wine patchwatcher thingy.
I patched the latest git sources with your patch
"$patch_subject"
The result: the patch $status_long.

Here is the patch and the log.
I hope this service is useful.  
Please send comments, suggestions, and complaints to dank@kegel.com.

_EOF_

    # don't email on success, too noisy
    case $status in
    success) ;;
    *) mailx -s "Patchwatcher: ${status_long}: $patch_subject" dank@kegel.com  < msg.dat
    ;;
    esac

    perl $TOP/dashboard.pl > index.html
    ftp $PATCHWATCHER_DEST <<_EOF_
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
    echo Processing patch $NEXT.txt:
    cat $NEXT.txt

    cd $WORK
    rm -rf golden
    mv active golden
    cp -a golden active
    cd active
    if ! patch -p1 < $PATCHES/$NEXT.txt > $PATCHES/$NEXT.log 2>&1
    then
       report_results patch $NEXT.txt  $NEXT.log
    else
       # TODO: need to run configure?
       # Note: don't use parallel build, we want to email a nice clean log
       if ! make 2>&1 | perl $TOP/trim-build-log.pl >> $PATCHES/$NEXT.log || ! grep "^Wine build complete" $PATCHES/$NEXT.log 
       then
           report_results build $NEXT.txt  $NEXT.log
       else
           report_results success $NEXT.txt  $NEXT.log
       fi
       cat $PATCHES/$NEXT.log
    fi
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
    ftp $PATCHWATCHER_DEST <<_EOF_
cd results
prompt
mput *.txt
mput *.log
put index.html
quit
_EOF_
fi
continuous_build
