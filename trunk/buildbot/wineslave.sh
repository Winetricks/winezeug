#!/bin/sh
# Start a wine buildbot slave
# Copyright 2011, Dan Kegel
# LGPL

set -e

TOP=$HOME/wineslave.dir

#----- Helper functions -----------------------------------------------------

usage() {
    echo "Usage: $0 command ..."
    echo "Commands:"
    echo "   destroy"
    echo "   install_prereqs"
    echo "   create BUILDMASTER:PORT USERNAME PASSWORD"
    echo "   start"
    echo "   tail"
    echo "   patch"
    echo "   configure"
    echo "   build"
    echo "   test"
    echo "   demo"

    system_info
    exit 1
}

system_osname() {
    # FIXME: do this portably
    lsb_release -d -s | tr -d '\012'
    echo ", "
    uname -r | tr -d '\012'
    echo ", "
    pulseaudio --version | tr -d '\012'
    echo ", "
    cat /proc/asound/version
}

system_cpuname() {
    # FIXME: do this portably
    cat /proc/cpuinfo  | grep "model name" | uniq | sed 's/model name.: //'
}

system_numcpus() {
    if test "$NUMBER_OF_PROCESSORS"
    then
        echo $NUMBER_OF_PROCESSORS
    elif sysctl -n hw.ncpu 2> /dev/null
    then
        # Mac, freebsd
        :
    else
        # x86 linux
        grep '^processor' /proc/cpuinfo | wc -l
    fi
}

system_ram_megabytes() {
    # FIXME: do this portably
    free | awk '/Mem:/ {printf("%d\n", $2 / 1024); }'
}

system_gpu() {
    # FIXME: do this portably
    glxinfo | egrep "OpenGL renderer string:|OpenGL version string" | sed 's/.*string: //'
}

system_info() {
    echo "os:    " `system_osname`
    echo "ram:   " `system_ram_megabytes` MB
    echo "cpu:   " `system_cpuname`
    echo "gpu:   " `system_gpu`
}

#----- Functions invoked by user when setting up or starting slave -----------

install_prereqs() {
    # For Ubuntu.  Other systems may differ.
    # Needed for buildbot
    sudo apt-get install python-dev python-virtualenv 
    # Needed to report on GPU type
    sudo apt-get install mesa-utils
    # Needed to apply patches
    sudo apt-get install autoconf
    # Needed to make repeated builds of same files go faster
    sudo apt-get install ccache
    # Needed to work around http://bugs.winehq.org/show_bug.cgi?id=28097
    # On Squeeze, add contrib to /etc/apt/sources.list for this to work
    sudo apt-get install ttf-mscorefonts-installer
    # Needed to pass rpcrt4 tests
    sudo apt-get install winbind
    # Needed to avoid gecko prompt
    sh ../install-gecko.sh
}

destroy() {
    if test -d $TOP
    then
        stop_slave || true
        rm -rf $TOP || true
    fi
}

# Create a slave and say how to connect to the build master
# Usage: create_slave buildmaster:port slavename slavepassword
create_slave() {
    (
    if test "$1" = ""
    then
        echo "need buildhost:port"
        exit 1
    fi
    if test "$2" = ""
    then
        echo "need slave name"
        exit 1
    fi
    if test "$3" = ""
    then
        echo "need slave password"
        exit 1
    fi
    mkdir -p $TOP
    cd $TOP
    test -d sandbox || virtualenv --no-site-packages sandbox
    cd $TOP/sandbox
    . bin/activate
    if false
    then
        easy_install buildbot-slave
    elif false
    then
        # Here's how to install from a source tarball
        # untested, copied from winemaster.sh
        wget -c http://buildbot.googlecode.com/files/buildbot-0.8.4p2.tar.gz
        tar -xzvf buildbot-0.8.4p2.tar.gz
        cd buildbot-0.8.4p2
        python setup.py install
        cd ..
    else
        # Here's how to install slave from trunk
        # (Needed to use git apply instead of patch)
        test -d buildbot-git || git clone git://github.com/buildbot/buildbot.git buildbot-git
        cd buildbot-git
        # use git to apply patches
        patch -p1 < $SRC/buildbot-git-apply.patch
        export PIP_USE_MIRRORS=true
        pip install -eslave
        cd ..
    fi
    buildslave create-slave slave $1 $2 $3
    cp $SRC/wineslave.sh $TOP/sandbox/bin/wineslave.sh
    chmod +x $TOP/sandbox/bin/wineslave.sh
    cp $SRC/*-ignore-*.patch $TOP/sandbox/bin
    )

    echo "Filling in $TOP/sandbox/slave/info/host with following info:"
    system_info
    system_info > $TOP/sandbox/slave/info/host

    echo "Please put your name and email address in $TOP/sandbox/slave/info/admin !"
}

start_slave() {
    (
    cd $TOP/sandbox
    . bin/activate
    buildslave start $VIRTUAL_ENV/slave
    )
}

stop_slave() {
    (
    cd $TOP/sandbox
    . bin/activate
    buildslave stop $VIRTUAL_ENV/slave
    )
}

# Shows how to bring up a demo slave that connects to a local buildbot.
# A real slave would connect to, say, buildbot.winehq.org instead of localhost.
demo() {
    destroy
    install_prereqs
    create_slave localhost:9989 example-slave pass
    start_slave
}

#--------- Functions used while slave is running; invoked by master.cfg ---------

# Apply patches needed to skip flaky tests
do_patch() {
    cd $TOP/sandbox/slave/runtests/build
    for p in $SRC/*-ignore-*.patch
    do
        echo $p
        patch -p1 < $p
    done
}

do_configure() {
    cd $TOP/sandbox/slave/runtests/build
    # Running make_makefiles without adding new source files to git
    # generates invalid Makefile.in's; let's hope each patch that adds a new
    # source file contains the needed Makefile.in changes.
    #tools/make_makefiles
    autoconf
    # ccache seems to bring build times down by about a factor 
    # of 2-3 on a wide range of machines
    CC="ccache gcc -m32" CFLAGS="-g -O0" ./configure
}

do_build() {
    cd $TOP/sandbox/slave/runtests/build
    make -j`system_numcpus`
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

do_prepare_wineprefix() {
    rm -rf $WINEPREFIX
    # winetricks vd=800x600
    ./wine reg add HKCU\\Software\\Wine\\Explorer /v Desktop /d Default
    ./wine reg add HKCU\\Software\\Wine\\Explorer\\Desktops /v Default /d 800x600
    # Avoid race condition with registry that caused some tests to not run
    # in a virtual desktop?
    server/wineserver -w
}

# Run all tests that don't require the display
do_background_tests() {
    (
    unset DISPLAY
    export WINEPREFIX=`pwd`/wineprefix-background
    do_prepare_wineprefix
    cd dlls
    for dir in *
    do
        if echo $HEADLESS_DLLS | grep -qw $dir && cd $dir/tests
        then
            make -k test || echo dir $dir failed
            cd ../..
        fi
    done
    cd ..
    cd programs
    for dir in *
    do
        if cd $dir/tests
        then
            make -k test || echo dir $dir failed
            cd ../..
        fi
    done
    )
}

# Run all tests that do require the display
do_foreground_tests() {
    (
    export WINEPREFIX=`pwd`/wineprefix-foreground
    do_prepare_wineprefix
    cd dlls
    for dir in *
    do
        if echo $HEADLESS_DLLS | grep -vqw $dir && cd $dir/tests
        then
            make -k test || echo dir $dir failed
            cd ../..
        fi
    done
    cd ..
    )
}

# Mark buggy tests as "to be skipped"
do_blacklist() {
    # http://bugs.winehq.org/show_bug.cgi?id=12053
    touch dlls/user32/tests/msg.ok
    touch dlls/user32/tests/win.ok
    touch dlls/user32/tests/input.ok
    # http://bugs.winehq.org/show_bug.cgi?id=28038
    touch dlls/wininet/tests/urlcache.ok
    # http://bugs.winehq.org/show_bug.cgi?id=28109
    touch dlls/winmm/tests/capture.ok
    # http://bugs.winehq.org/show_bug.cgi?id=28048
    touch dlls/winmm/tests/wave.ok
    # Blacklist until http://www.winehq.org/pipermail/wine-patches/2011-August/105358.html in
    touch dlls/winhttp/tests/winhttp.ok
    # http://bugs.winehq.org/show_bug.cgi?id=28101 - ftp tests take 1 minute
    touch dlls/wininet/tests/ftp.ok
    # http://bugs.winehq.org/show_bug.cgi?id=28102
    touch dlls/ws2_32/tests/sock.ok
    # http://bugs.winehq.org/show_bug.cgi?id=28108
    touch dlls/urlmon/tests/url.ok
    # http://bugs.winehq.org/show_bug.cgi?id=28216
    touch dlls/shell32/tests/shlfolder.ok

    # System-specific blacklists
    case `system_osname` in
    *"Ubuntu 10"*)
        # http://bugs.winehq.org/show_bug.cgi?id=28071
        # Just need alsa-base-1.0.24 or later
        touch dlls/winmm/tests/mci.ok
        ;;
    esac
}

do_test() {
    cd $TOP/sandbox/slave/runtests/build
    do_blacklist

    # Many tests only work in english locale
    LANG=en_US.UTF-8
    export LANG

    # Get elapsed time of each test
    WINETEST_WRAPPER=time
    export WINETEST_WRAPPER

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
        do_foreground_tests
        # Under set -e, script aborts early for foreground failures, and on wait %1 for background failures,
        # making it hard to show the background log before aborting.
        # So use set +e, and check status of background and foreground manually.
        foreground_status=$?
        set +e
        wait %1
        background_status=$?
        cat background.log
        if test $foreground_status -ne 0 || test $background_status -ne 0
        then
            echo "FAIL: background_status $background_status, foreground_status $foreground_status"
            exit 1
        fi
        set -e
    fi
}

#--------- Main program ---------------------------------------------------------

SRC=`dirname $0`
SRC=`cd $SRC; pwd`

if ! test "$1"
then
    usage
fi

while test "$1"
do
    arg="$1"
    shift
    case "$arg" in
    info) system_info;;
    install_prereqs) install_prereqs;;
    destroy) destroy;;
    create) create_slave $1 $2 $3; shift 3;;
    start) start_slave;;
    stop) stop_slave;;
    tail) tail -f $TOP/sandbox/slave/twistd.log;;
    patch) do_patch;;
    configure) do_configure;;
    build) do_build;;
    test) do_test;;
    demo) demo;;
    *) usage;;
    esac
done
