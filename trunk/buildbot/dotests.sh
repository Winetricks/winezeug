#!/bin/sh
# Script to build and test wine under various conditions,
# skipping tests listed in bugzilla as failing.

set -e
set -x

SRC=`dirname $0`
SRC=`cd $SRC; pwd`

usage() {
    cat <<_EOF_
Usage: $0 command
Commands:
   goodtests
   badtests
   flakytests
   valgrindtests
   retry_flakytests
   crashytests
_EOF_
    exit 1
}

# DLLs whose tests don't need DISPLAY set
HEADLESS_DLLS="\
    advpack amstream avifil32 browseui cabinet comcat credui crypt32 \
    cryptnet cryptui d3d10 d3d10core d3dxof \
    dispex dmime dmloader dnsapi dplayx dxdiagn dxgi faultrep fusion \
    gameux hlink imagehlp imm32 inetcomm inetmib1 infosoft iphlpapi \
    itss jscript localspl localui lz32 mapi32 mlang msacm32 \
    mscms mscoree msi mstask msvcp90 msvcr90 msvcrt msvcrtd msvfw32 \
    msxml3 netapi32 ntdll ntdsapi ntprint odbccp32 oleacc \
    oledb32 pdh propsys psapi qedit qmgr \
    rasapi32 rpcrt4 rsaenh schannel secur32 serialui setupapi \
    shdocvw snmpapi spoolss sti twain_32 urlmon userenv \
    uxtheme vbscript version wer windowscodecs winhttp \
    winspool.drv wintab32 wintrust wldap32 xinput1_3 xmllite"

# DLLs with some slow tests (but no 3d, and no listening sockets, and no forcing the mouse)
SLOW_DLLS="\
    dlls/advapi32 dlls/explorerframe dlls/kernel32 dlls/shell32 dlls/winmm"

create_wineprefix() {
    export WINEPREFIX=`pwd`/wineprefix-$1
    rm -rf $WINEPREFIX
    ./wine cmd /c echo "initializing wineprefix"

    # Set a virtual desktop; helps when you can't always have a monitor connected
    cat > vd.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"
[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"="800x600"

_EOF_
    ./wine regedit vd.reg
    # Sadly, you have to wait for wineserver to finish before the virtual desktop takes effect
    server/wineserver -w
    #./wine winemine
    #sleep 20
    #exit 1
}

# Run all tests that don't require the display
do_background_tests() {
    background_errors=0
   
    OLDDISPLAY=DISPLAY
    unset DISPLAY
    create_wineprefix background
    cd dlls
    for dir in *
    do
        if echo $HEADLESS_DLLS | grep -qw $dir && test -d $dir/tests && cd $dir/tests
        then
            make -k test || background_errors=`expr $background_errors + 1`
            cd ../..
        fi
    done
    cd ..
    cd programs
    for dir in *
    do
        if test -d $dir/tests && cd $dir/tests
        then
            make -k test || background_errors=`expr $background_errors + 1`
            cd ../..
        fi
    done

    # probably not needed, but...
    case "$OLDDISPLAY" in
    "") ;;
    *) DISPLAY=$OLDDISPLAY; export DISPLAY;;
    esac

    case $background_errors in
    0) echo "do_background_tests pass."; return 0 ;;
    *) echo "do_background_tests fail: $background_errors directories had errors." ; return 1;;
    esac
}

# Run all tests that do require the display
do_foreground_tests() {
    foreground_errors=0
    create_wineprefix foreground
    if test -f wine_gecko-1.3-x86-dbg.tar.bz2
    then
        rm -rf $WINEPREFIX/drive_c/windows/system32/gecko/1.3
        mkdir -p $WINEPREFIX/drive_c/windows/system32/gecko/1.3
        tar -xjvf wine_gecko-1.3-x86-dbg.tar.bz2 -C $WINEPREFIX/drive_c/windows/system32/gecko/1.3
    fi
    cd dlls
    for dir in *
    do
        if echo $HEADLESS_DLLS $SLOW_DLLS | grep -vqw $dir && test -d $dir/tests && cd $dir/tests
        then
            make -k test || foreground_errors=`expr $foreground_errors + 1`
            cd ../..
        fi
    done
    cd ..

    # In win64, currently iexplore and rpcss hang around after tests
    # causing buildbot to not detect that tests have completed.
    server/wineserver -k

    case $foreground_errors in
    0) echo "do_foreground_tests pass."; return 0 ;;
    *) echo "do_foreground_tests fail: $foreground_errors directories had errors." ; return 1;;
    esac
}

# Run all tests in given directory (or directories)
do_subset_tests() {
    subset_errors=0

    create_wineprefix subset
    for dir
    do
        if test -d $dir/tests && cd $dir/tests
        then
            ../../../wine cmd /c echo "initializing wineprefix so it isn't included in timeout"
            make -k test || subset_errors=`expr $subset_errors + 1`
            cd ../../..
            server/wineserver -k
        fi
    done

    case $subset_errors in
    0) echo "do_subset_tests pass."; return 0 ;;
    *) echo "do_subset_tests fail: $subset_errors directories had errors." ; return 1;;
    esac
}

# Blacklist format
# test condition [bug]
# Tests may appear multiple times in the list.
# Supported conditions:
# FLAKY - fails sometimes
# WICKED - fails sometimes, but if you run it again, still fails
# CRASHY - crashes sometimes
# SYS - always fails on some systems, not on others
# HEAP - fails or crashes if warn+heap
# NOTTY - test fails if output redirected
# BAD64 - always fails on 64 bits
# ATI - fails on ATI graphics

# Return tests that match given criterion
# Usage: get_blacklist regexp
# e.g.
#  get_blacklist 'SYS' gets all tests that reliably crash on some systems
#  get_blacklist 'WICKED|FLAKY|CRASHY' gets all tests that fail or crash occasionally

get_blacklist() {
    egrep "$1" < $SRC/dotests_blacklist.txt | awk '{print $1}' | sort -u
}

# If this was a really simple change, say which directory to build/test.
# i.e.
# If a DLL's tests change, return that DLL.
# If a program or its tests change, return that program.
is_simple_change() {
    # (Ideally buildbot would tell us this, but for now,
    # grub around in git.)
    # Get a list of modified directories
    # (ignoring created or deleted files for now)
    time git status | grep modified: | grep -v configure | awk '{print $3}' | sed 's,/[^/]*$,,' | sort -u > dirs.txt

    sed 's,/tests$,,' < dirs.txt | sort -u > basedirs.txt

    # Did only a single DLL's test directory change?
    if test `wc -l < dirs.txt` = 1 && grep 'dlls/.*/tests$' < dirs.txt
    then
        cat basedirs.txt
        return 0
    fi

    # Did only a single program (and/or its tests) change?
    if test `wc -l < basedirs.txt` = 1 && grep programs < basedirs.txt > /dev/null
    then
        cat basedirs.txt
        return 0
    fi

    echo "Not a simple change; here's the list of changed directories" >&2
    cat dirs.txt >&2
    return 1
}

# Run all the flaky tests.  If one fails once, try it one more time before declaring failure.
do_retry_flakytests() {
    flaky_errors=0
    create_wineprefix flaky
    if test -f wine_gecko-1.3-x86-dbg.tar.bz2
    then
        rm -rf $WINEPREFIX/drive_c/windows/system32/gecko/1.3
        mkdir -p $WINEPREFIX/drive_c/windows/system32/gecko/1.3
        tar -xjvf wine_gecko-1.3-x86-dbg.tar.bz2 -C $WINEPREFIX/drive_c/windows/system32/gecko/1.3
    fi
    for badtest in `get_blacklist FLAKY`
    do
        bugs="`grep $badtest < $SRC/dotests_blacklist.txt | awk '{print $3}' | sort -u | tr '\012' ' '`"
        badtestdir=${badtest%/*}
        badtestfile=${badtest##*/}
        cd $badtestdir
        if make $badtestfile
        then
            echo "$badtest passed on first try even though it's marked flaky"
        else
            echo "$badtest did not pass on first try, but it's marked flaky, so trying again, see bug $bugs."
            if make $badtestfile
            then
                echo "$badtest passed on second try."
            else
                echo "$badtest FAILED on second try; see bug $bugs."
                flaky_errors=`expr $flaky_errors + 1`
            fi
        fi
        cd ../../..
    done
    echo "badtests done, $flaky_errors tests failed both tries."
    return $flaky_errors
}

# DLLs to run through valgrind
# For now, just run one that's known to be broken
VALGRIND_WHITELIST_DLLS="advapi32"
# Here are a set known to be good:
#    amstream avifil32 comcat credui cryptnet 
#    cryptui d3d10core d3d10 d3dxof dmloader 
#    dnsapi dpnet dxgi faultrep gameux inetmib1 
#    infosoft itss localui mapi32"

# Run VALGRIND_WHITELIST_DLLS though valgrind
# FIXME: replace this with code to run just the DLL involved in a simple change through valgrind
do_valgrind_tests() {
    valgrind_errors=0
    create_wineprefix valgrind
    # FIXME: move this into create_wineprefix
    if test -f wine_gecko-1.3-x86-dbg.tar.bz2
    then
        rm -rf $WINEPREFIX/drive_c/windows/system32/gecko/1.3
        mkdir -p $WINEPREFIX/drive_c/windows/system32/gecko/1.3
        tar -xjvf wine_gecko-1.3-x86-dbg.tar.bz2 -C $WINEPREFIX/drive_c/windows/system32/gecko/1.3
    fi

    # Start winemine so wineboot doesn't get run by valgrind (too slow?)
    ./wine winemine &
    winemine_pid=$!

    sleep 1

    VALGRIND_OPTS="--trace-children=yes --track-origins=yes \
      --gen-suppressions=all --suppressions=$SRC/suppressions \
      --leak-check=no --num-callers=20  --workaround-gcc296-bugs=yes \
      --vex-iropt-precise-memory-exns=yes"
    export VALGRIND_OPTS

    for test in $VALGRIND_WHITELIST_DLLS
    do
        cd dlls/$test/tests

        rm -f *.ok
        if ! WINETEST_WRAPPER="alarum 300 valgrind" make test
        then
            echo "$test FAILED"
            valgrind_errors=`expr $valgrind_errors + 1`
        fi
        cd ../../..
    done
    kill $winemine_pid
    server/wineserver -k
    echo "do_valgrind_tests done, $valgrind_errors tests had failures."
    return $valgrind_errors
}

# Run all the known good tests
# This takes a while, so speed things up a bit by running some tests in background
do_goodtests() {
    # Skip all tests that might fail
    match='SYS|WICKED|FLAKY|CRASHY'
    case `uname -m` in
    x86_64) match="$match|BAD64";;
    esac
    echo "Checking WINEDEBUG ($WINEDEBUG)"
    case "$WINEDEBUG" in
    *warn+heap*) match="$match|HEAP" ;;
    esac
    if ! test -t 1
    then
        match="$match|NOTTY"
    fi
    if lspci | grep VGA.*ATI
    then
        match="$match|ATI"
    fi
    if test `pgrep pulseaudio`
    then
        match="$match|PULSE"
    fi

    blacklist=`get_blacklist "$match"`
    touch $blacklist

    echo "Checking whether change is so simple we don't need to run all tests"
    if dir=`is_simple_change`
    then
        # Run tests five times, it's cheap
        # FIXME: remove this when cmd is fixed
        case $dir in
        programs/cmd*) n=1 ;;
        *) n=5 ;;
        esac
        for run in `seq 1 $n`
        do
            echo run $run of $n
            if ! do_subset_tests $dir
            then
                echo "FAIL: subset_status $?"
                exit 1
            fi
            if cd $dir/tests
            then
                make testclean
                cd ../../..
            fi
            touch $blacklist
        done
        echo "goodtests on single directory $dir done"
        return 0
    fi

    if test "$DISPLAY" = ""
    then
        echo "DISPLAY not set, doing headless tests"
        do_background_tests
    else
        echo "DISPLAY set, doing full tests"
        # Run two groups of tests in parallel
        # The background tests don't need the display, and use their own wineprefix
        # Neither use much CPU, so this should save time even on slow computers
        do_background_tests > background.log 2>&1 &
        # A few foreground tests are safe to do in their own virtual desktop, and are slow, so spawn them off now:
        do_subset_tests $SLOW_DLLS > slow.log 2>&1 &

        # Under set -e, script aborts early for foreground failures, and on wait %1 for background failures,
        # making it hard to show the background log before aborting.
        # So use set +e, and check status of background and foreground manually.
        set +e
        do_foreground_tests
        foreground_status=$?
        # The tests marked as flaky require a little special treatment
        do_retry_flakytests
        flaky_status=$?
        wait %1
        background_status=$?
        cat background.log
        wait %2
        slow_status=$?
        cat slow.log

        if test $foreground_status -ne 0 || test $flaky_status -ne 0 || test $background_status -ne 0 || test $slow_status -ne 0
        then
            echo "FAIL: background_status $background_status, foreground_status $foreground_status, flaky_status $flaky_status, slow_status $slow_status"
            exit 1
        fi
        set -e
    fi
    echo "goodtests done."
}

# Run tests that are expected to fail for given reason
# Usage: do_badtests regexp
# e.g.
#  do_badtests . - to get all tests that fail somewhere sometimes
#  do_badtests 'WICKED|FLAKY|CRASHY' - to get only the unreliably unreliable tests
do_badtests() {
    for badtest in `get_blacklist $1`
    do
        reasons="`grep $badtest < $SRC/dotests_blacklist.txt | awk '{print $2}' | sort -u | tr '\012' ' '`"
        bugs="`grep $badtest < $SRC/dotests_blacklist.txt | awk '{print $3}' | sort -u | tr '\012' ' '`"
        if ! test "$bugs"
        then
            echo "$badtest is listed as $reasons, but is not listed as a bug, so skipping."
            continue
        fi
        badtestdir=${badtest%/*}
        badtestfile=${badtest##*/}
        (
        cd $badtestdir
        if make -k test $badtestfile
        then
            echo "$badtest passed; blacklist says $reasons, see bug $bugs."
        else
            echo "$badtest FAILED; blacklist says $reasons, see bug $bugs."
        fi
        )
    done
    echo "badtests $1 done."
}

if ! test "$1"
then
    usage
fi

if test x`which alarum` != x
then
    # Shut down each test after 5 minutes. (60 seconds should be fine,
    # but cmd and mshtml/events seem to time out there.)
    WINETEST_WRAPPER="alarum 300"
    export WINETEST_WRAPPER
fi

# If you want debug gecko, put it in current directory before running
#if ! test -f wine_gecko-1.3-x86-dbg.tar.bz2
#then
#    wget http://downloads.sourceforge.net/wine/wine_gecko-1.3-x86-dbg.tar.bz2
#fi

# Many tests only work in english locale
# FIXME Someday change this to choose a non-english locale
LANG=en_US.UTF-8
export LANG

arg="$1"
shift
case "$arg" in
good*)   do_goodtests               ;;
bad*)    do_badtests .              ;;
flaky*)  do_badtests FLAKY          ;;
retry_flaky*) do_retry_flakytests   ;;
valgrind*) do_valgrind_tests        ;;
crashy*) do_badtests CRASHY         ;;
*) usage;;
esac
