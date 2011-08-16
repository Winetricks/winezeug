#!/bin/sh
# Executable version of http://buildbot.net/buildbot/tutorial/
# Modified to start a wine buildbot instead of the tutorial
# Copyright 2011, Dan Kegel
# Dual licensed, GPL and LGPL, suitable for inclusion in both buildbot and wine

set -x
set -e

SRC=`dirname $0`
SRC=`cd $SRC; pwd`
TOP=$HOME/tmp/buildbot

if test "$NUMBER_OF_PROCESSORS"
then
    NCPUS=$NUMBER_OF_PROCESSORS
elif sysctl -n hw.ncpu
then
    # Mac, freebsd
    NCPUS=`sysctl -n hw.ncpu`
else
    # x86 linux
    NCPUS=`grep '^processor' /proc/cpuinfo | wc -l`
fi

# Get email address of user from environment for use by the 'try' command.
# If not set, default to username@hostname.
EMAIL=${EMAIL:-$LOGNAME@`hostname`}

install_prereqs() {
    # For Ubuntu.  Other systems may differ.
    # Needed for buildbot
    sudo apt-get install python-dev python-virtualenv 
    # Needed to apply patches
    sudo apt-get install autoconf
    # Needed to work around http://bugs.winehq.org/show_bug.cgi?id=28097
    sudo apt-get install ttf-mscorefonts-installer
    # Needed to pass rpcrt4 tests
    sudo apt-get install winbind
}

destroy() {
    stop_master || true
    stop_slave || true
    rm -rf $TOP || true
}

init_master() {
    (
    # Master
    mkdir -p $TOP
    cd $TOP
    virtualenv --no-site-packages sandbox
    cd $TOP/sandbox
    . bin/activate
    if false
    then
        easy_install buildbot
    elif false
    then
        # Here's how to install from a source tarball
        wget -c http://buildbot.googlecode.com/files/buildbot-0.8.4p2.tar.gz
        tar -xzvf buildbot-0.8.4p2.tar.gz
        cd buildbot-0.8.4p2
        python setup.py install
        cd ..
    else
        # Here's how to install master from trunk
        # (Needed until buildbot-0.8.5 is released,
        # since it has fixes for the try server / mail notifier.)
        # BTW rerunning 'pip install -emaster' takes less than a second, 
        # and seems to be how buildbot developers test their code
        test -d buildbot-git || git clone git://github.com/buildbot/buildbot.git buildbot-git
        cd buildbot-git
        export PIP_USE_MIRRORS=true
        pip install -emaster
        cd ..
    fi
    buildbot create-master master
    )
}

start_master() {
    (
    cd $TOP/sandbox
    . bin/activate
    cp $SRC/master.cfg $VIRTUAL_ENV/master
    buildbot start $VIRTUAL_ENV/master
    )
}

stop_master() {
    (
    cd $TOP/sandbox
    . bin/activate
    buildbot stop $VIRTUAL_ENV/master
    )
}

init_slave() {
    (
    mkdir -p $TOP
    cd $TOP
    test -d sandbox || virtualenv --no-site-packages sandbox
    cd $TOP/sandbox
    . bin/activate
    easy_install buildbot-slave
    buildslave create-slave slave localhost:9989 example-slave pass
    cp $SRC/winebuildbot.sh $TOP/sandbox/bin/winebuildbot.sh
    chmod +x $TOP/sandbox/bin/winebuildbot.sh
    cp $SRC/*-ignore-*.patch $TOP/sandbox/bin
    )
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

# Shows how to bring up a demo master and slave.
demo() {
    destroy
    install_prereqs
    init_master
    start_master
    init_slave
    start_slave
}

# Useful for testing bot.sh or master.cfg changes
restart() {
    stop_master || true
    stop_slave || true
    init_master
    start_master
    init_slave
    start_slave
}

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
    CFLAGS="-g -O0" ./configure
}

do_build() {
    cd $TOP/sandbox/slave/runtests/build
    make -j$NCPUS
}

do_test() {
    cd $TOP/sandbox/slave/runtests/build
    rm -rf wineprefix
    export WINEPREFIX=`pwd`/wineprefix
    # Many tests only work in english locale
    LANG=en_US.UTF-8
    # winetricks vd=800x600
    ./wine reg add HKCU\\Software\\Wine\\Explorer /v Desktop /d Default
    ./wine reg add HKCU\\Software\\Wine\\Explorer\\Desktops /v Default /d 800x600
    # winetricks nocrashdialog
    ./wine reg add HKCU\\Software\\Wine\\WineDbg /v ShowCrashDialog /t REG_DWORD /d 0
    # Blacklist some tests
    # http://bugs.winehq.org/show_bug.cgi?id=12053
    touch dlls/user32/tests/msg.ok
    touch dlls/user32/tests/win.ok
    touch dlls/user32/tests/input.ok
    # http://bugs.winehq.org/show_bug.cgi?id=28038
    touch dlls/wininet/tests/urlcache.ok
    # my machine fails with "capture.c:148: Test failed: waveInOpen(1)"
    touch dlls/winmm/tests/capture.ok
    # http://bugs.winehq.org/show_bug.cgi?id=28048
    touch dlls/winmm/tests/wave.ok
    # Blacklist until http://www.winehq.org/pipermail/wine-patches/2011-August/105358.html in
    touch dlls/winhttp/tests/winhttp.ok
    # Avoid race condition with registry that caused some tests to not run
    # in a virtual desktop?
    server/wineserver -w
    # Get elapsed time of each test
    WINETEST_WRAPPER=time make -k test
}

do_try() {
    if test "$1" = ""
    then
        echo "need patch name"
        exit 1
    fi
    who=$2
    subject=$3
    (
    cd $TOP/sandbox
    . bin/activate
    # FIXME: import username and password from another file so
    # it doesn't show up in svn.  Must match those in master.cfg.
    # FIXME: Use real hostname for master.
    # Always use -p 1 for wine patches, since that's the project's convention.
    buildbot try $wait --who $who --properties=comment="$subject" --connect=pb --master=127.0.0.1:5555 --username=fred --passwd=trybot --diff=$1 -p 1
    )
}

# Try the most recent not-yet-done patch series from source.winehq.org/patches
do_pulltry() {
    series=`perl parsepatch.pl 1`
    if test "$series"
    then
        # For now, just concatenate series together into one big patch
        rm -f series_*.patch
        for id in $series
        do
            wget -O series_$id.patch http://source.winehq.org/patches/data/$id
        done
        cat series_*.patch > series.patch
        author_email=`grep '^From:' < series.patch | head -n 1 | sed 's/^From: //;s/.*<//;s/>.*//'`
        subject="`grep '^Subject:' < series.patch | uniq`"
        do_try `pwd`/series.patch $author_email "${id}: ${subject}"
    fi
}

# Sit and test new patches forever
do_patchwatcher() {
    wait="--wait"
    while true
    do
       do_pulltry
       sleep 10
    done
}

while test "$1"
do
    arg="$1"
    shift
    case "$arg" in
    d|destroy) destroy;;
    ip|install_prereqs) install_prereqs;;
    im|init_master) init_master;;
    sm|start_master) start_master;;
    is|init_slave) init_slave;;
    ss|start_slave) start_slave;;
    tm|stop_master) stop_master;;
    ts|stop_slave) stop_slave;;
    lm|log_master) tail -f $TOP/sandbox/master/twistd.log;;
    ls|log_slave) tail -f $TOP/sandbox/slave/twistd.log;;
    patch) do_patch;;
    configure) do_configure;;
    build) do_build;;
    test) do_test;;
    restart) restart;;
    demo) demo;;
    pulltry) do_pulltry;;
    pw|patchwatcher) do_patchwatcher;;
    try) do_try $1 $EMAIL; shift;;
    *) echo "bad arg; expected destroy, install_prereqs, {init,start,log}_{master,slave}, {patch,configure,build,test}, restart, try PATCH, or demo"; exit 1;;
    esac
done
