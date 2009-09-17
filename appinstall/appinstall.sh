#!/bin/sh
# Script to automate Wine testing.
# Copyright 2009 Austin English
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
#
# Script info:
# This script is a wrapper around the various AutoHotKey scripts, the real
# wine app tester. All this script does is download the AHK scripts, cleanup
# WINEPREFIX's, use winetricks to install redistributables, grep the result logs
# for regressions/failures, and finally upload the results to a server for public view.

# TODO:
# Depends on GNU/Linuxisms....e.g., wget/sha1sum. Could be more portable, but then again
# we'd have to test Wine/these tests on all those platforms. Because of wine/OS bugs,
# Wine doesn't work as well on, e.g., OS X as it does on, e.g., Ubuntu.
# Testing those various OS's is not in the scope of Appinstall, but more the area of winetest.

set -x

WINE=${WINE:-wine}
WINEPREFIX=${WINEPREFIX:-$HOME/.wine-appinstall}
APPINSTALL_CACHE=${APPINSTALL_CACHE:-$HOME/.appinstallcache}
WORKDIR=`pwd`
TAG=${1:-`date -u +%Y-%m-%d`}
# Ensure those variables are used by later subcommands, e.g., winetricks
export WINE
export WINEPREFIX
export APPINSTALL_CACHE

mkdir -p "$APPINSTALL_CACHE"
cd "$APPINSTALL_CACHE"

# From winetricks:
die() {
  echo "$@"
  exit 1
}

try() {
    echo Executing "$@"
    "$@"
    status=$?
    if test $status -ne 0
    then
        die "Note: command '$@' returned status $status.  Aborting."
    fi
}

# Helper functions
cleanup() {
    rm -rf "$WINEPREFIX"
    rm -rf "$APPINSTALL_CACHE"/*.ahk
    rm -rf "$APPINSTALL_CACHE"/*.txt
    rm -rf "$APPINSTALL_CACHE"/helper_functions*
    rm -rf "$APPINSTALL_CACHE"/init_tests*
    rm -rf "$APPINSTALL_CACHE"/test_list*
}

prep_prefix() {
    # FIXME: This shouldn't depend on an installed wine.
    wineserver -k || true
    rm -rf "$WINEPREFIX"
    $WINE wineboot
    # We want to remove Z:\, but it's foobaring up when I do...for now, ignore.
    # rm -f "$WINEPREFIX"/dosdevices/z\:
    ln -s "$APPINSTALL_CACHE" "$WINEPREFIX"/drive_c/appinstall
    ls  "$WINEPREFIX"/drive_c/appinstall
}

runwait() {
    # Inspired by http://www.bashcookbook.com/bashinfo/source/bash-4.0/examples/scripts/timeout3

    timeout=1800 # Total timeout time, in seconds
    interval=5 # time between checks, in seconds

    $@ &
    cmdpid=$!
    (
        t=$timeout
        while [ $t -gt 0 ]
        do
            if [ ! "`ps | grep $cmdpid`" ] # Yes, this is ugly. Should be `ps $cmdpid`, which returns 0 if the process exists, and 1 otherwise, but that fails for some reason...this should be fine.
            then
                echo "process doesn't exist" >> "$APPINSTALL_CACHE"/processes.txt
                break 2
            fi
        sleep $interval\s
        t=`expr $t - $interval`
        done
        
        kill -9 $cmdpid && echo "$@ Process killed!" >> "$APPINSTALL_CACHE"/processes.txt || echo "$@ exited normally." >> "$APPINSTALL_CACHE"/processes.txt
    ) 2> /dev/null

}

verifyahk() {
    if [ ! "`sha1sum autohotkey.exe`" = "10aae5e538327d5bdb54e4d9bc0c8971b2a831a3  autohotkey.exe" ] ; then
    die "AutoHotkey sha1sum failed."
    fi
}

# Make sure Wine and friends are installed...otherwise, this script doesn't do much :-)
if [ ! -x "`which "$WINE"`" ]
then	
  echo "Cannot find wine: '($WINE)'!"
  exit 1
fi

if [ ! -x "`which sha1sum`" ]
then
  echo "Cannot find sha1sum!"
  exit 1
fi

if [ ! -x "`which wget`" ]
then
  echo "Cannot find wget!"
  exit 1
fi

# Download winetricks. We use it for quite a few things...
rm -rf winetricks "$WINEPREFIX"
wget http://winezeug.googlecode.com/svn/trunk/winetricks

# Get AutoHotKey:
if [ -f autohotkey.exe ] ; then
    verifyahk
    echo "AutoHotKey is in cache and checksum matched. Good to go."
else
    wget http://winezeug.googlecode.com/svn/trunk/appinstall/tools/autohotkey/autohotkey.exe
    verifyahk
fi

# Make sure there's no old stuff, just in case:
cleanup

#Don't forget their helper files!
wget http://winezeug.googlecode.com/svn/trunk/appinstall/scripts/helper_functions
wget http://winezeug.googlecode.com/svn/trunk/appinstall/scripts/init_test

#---------------------------
# Test time

# Now we'll need to setup groups of tests, depending on winetricks needs.
# We don't want to use winetricks to work around wine bugs, only to install redistributables.

# Winetricks not needed:
for x in \
    7-zip.ahk \
    autohotkey.ahk \
    builtin-console.ahk \
    builtin-gui.ahk \
    ccleaner-220.ahk \
    clamwin.ahk \
    dirac.ahk \
    excelviewer03.ahk \
    firefox35.ahk \
    gimp.ahk \
    ida49.ahk \
    imagetest.ahk \
    kmeleon-152.ahk \
    kmeleon-153.ahk \
    mpc.ahk \
    nestopia.ahk \
    notepad.ahk \
    notepadpp.ahk \
    pidgin.ahk \
    ppviewer03.ahk \
    putty.ahk \
    python26.ahk \
    reg.ahk \
    regedit.ahk \
    reshacker.ahk \
    sbw.ahk \
    startup_cpl.ahk \
    stinger.ahk \
    thunderbird.ahk \
    vlc86f.ahk \
    vlc99.ahk \
    wordviewer03.ahk

    do
        prep_prefix
        cd "$WINEPREFIX"/drive_c/appinstall
        wget "http://winezeug.googlecode.com/svn/trunk/appinstall/scripts/$x"
        echo $x >> test_list
        runwait $WINE "C:\appinstall\autohotkey.exe" $x
done

# corefonts + gecko
for x in \
    photoshopcs2.ahk

    do
        prep_prefix
        sh winetricks -q corefonts gecko
        cd "$WINEPREFIX"/drive_c/appinstall
        wget "http://winezeug.googlecode.com/svn/trunk/appinstall/scripts/$x"
        echo $x >> test_list
        runwait $WINE "C:\appinstall\autohotkey.exe" "$x"
done

# mfc42:
for x in \
    win92.ahk

    do
        prep_prefix
        sh winetricks -q mfc42
        cd "$WINEPREFIX"/drive_c/appinstall
        wget "http://winezeug.googlecode.com/svn/trunk/appinstall/scripts/$x"
        echo $x >> test_list
        runwait $WINE "C:\appinstall\autohotkey.exe" "$x"
done

# gecko + mfc42:
for x in \
    lockdown.ahk

    do
        prep_prefix
        sh winetricks -q gecko mfc42
        cd "$WINEPREFIX"/drive_c/appinstall
        wget "http://winezeug.googlecode.com/svn/trunk/appinstall/scripts/$x"
        echo $x >> test_list
        runwait $WINE "C:\appinstall\autohotkey.exe" "$x"
done

# gecko:
for x in \
    pex.ahk

    do
        prep_prefix
        sh winetricks -q gecko
        cd "$WINEPREFIX"/drive_c/appinstall
        wget "http://winezeug.googlecode.com/svn/trunk/appinstall/scripts/$x"
        echo $x >> test_list
        runwait $WINE "C:\appinstall\autohotkey.exe" "$x"
done

# Take a break, just in case the last tests takes a while to exit
sleep 1m

cd "$APPINSTALL_CACHE"

# Make sure all tests completed:
while read LINE
do
testname=`basename $LINE .ahk`
grep "TEST COMPLETE" "$testname-result.txt"
status=$?
if [ $status -eq 2 ] ; then
    echo "$testname result file not found...wtf mate? Test failed." >> complete-result.txt
    exit 2
elif [ $status -eq 0 ] ; then
    echo "$testname test completed. Test passed." >> complete-result.txt
elif [ $status -eq 1 ] ; then
    echo "$testname test did not complete. Test failed." >> complete-result.txt
else
    echo "Unknown error when checking test completions. Test failed." >> complete-result.txt
fi
done < test_list

# Grep through logs...
grep "TEST ABORTED" *-result.txt >> summary.txt 2>&1
status=$?
if [ $status -eq 2 ] ; then
    echo "No result files found...wtf mate?" >> summary.txt
    exit 2
elif [ $status -eq 1 ] ; then
    echo "No tests aborted early." >> summary.txt
elif [ $status -eq 0 ] ; then
    echo "Some test aborted early! Investigate." >> summary.txt
else
    echo "Unknown error when grepping result files. Exiting." >> summary.txt
fi

grep "Test failed" *-result.txt >> summary.txt 2>&1
status=$?
if [ $status -eq 2 ] ; then
    echo "No result files found...wtf mate?" >> summary.txt
    exit 2
elif [ $status -eq 1 ] ; then
    echo "All tests passed" >> summary.txt
elif [ $status -eq 0 ] ; then
    echo "Some tests failed...investigate!" >> summary.txt
else
    echo "Unknown error when grepping result files. Exiting." >> summary.txt
fi

grep "TODO_FIXED" *-result.txt >> summary.txt 2>&1
status=$?
if [ $status -eq 2 ] ; then
    echo "No result files found...wtf mate?" >> summary.txt
    exit 2
elif [ $status -eq 1 ] ; then
    echo "All TODO's failed." >> summary.txt
elif [ $status -eq 0 ] ; then
    echo "Some TODO_FIXED...investigate!" >> summary.txt
else
    echo "Unknown error when grepping result files. Exiting." >> summary.txt
fi

grep "Process killed" processes.txt >> summary.txt 2>&1
status=$?
if [ $status -eq 2 ] ; then
    echo "Process status file not found...wtf mate?" >> summary.txt
    exit 2
elif [ $status -eq 1 ] ; then
    echo "No runaway processes." >> summary.txt
elif [ $status -eq 0 ] ; then
    echo "Some processes had to be executed with extreme prejudice. INVESTIGATE!" >> summary.txt
else
    echo "Unknown error when grepping result files. Exiting." >> summary.txt
fi

chmod 644 *.txt
ssh $APPINSTALL_SSH_USER@$APPINSTALL_SSH_SERVER mkdir -p logs/appinstall-$TAG
scp *.txt $APPINSTALL_SSH_USER@$APPINSTALL_SSH_SERVER:~/logs/appinstall-$TAG

cleanup

exit 0
