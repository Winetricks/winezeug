#!/bin/sh
# Start a wine buildbot master
# Copyright 2011, Dan Kegel
# LGPL

set -x
set -e

TOP=$HOME/winemaster.dir

# Get email address of user from environment for use by the 'try' command.
# If not set, default to username@hostname.
EMAIL=${EMAIL:-$LOGNAME@`hostname`}

#----- Helper functions -----------------------------------------------------

usage() {
    set +x
    echo "Usage: $0 command ..."
    echo "Commands:"
    echo "   destroy"
    echo "   install_prereqs"
    echo "   create"
    echo "   start"
    echo "   tail"
    echo "   demo"

    exit 1
}

system_osname() {
    # FIXME: do this portably
    lsb_release -d -s | tr -d '\012'
    echo ", "
    uname -r | tr -d '\012'
}

#----- Functions invoked by user when setting up or starting master -----------

install_prereqs_apt() {
    # Needed for buildbot
    sudo apt-get install python-dev python-virtualenv
    # Needed for fetching buildbot from git
    sudo apt-get install git || sudo apt-get install git-core
    # Needed for parsepatch.pl
    sudo apt-get install libdatetime-format-mail-perl
}

install_prereqs_macports() {
    # For Mac OS X with MacPorts.
    # Needed for buildbot
    sudo port install py-virtualenv
    # Needed for fetching buildbot from git
    sudo port install git-core
    # Needed for parsepatch.pl
    sudo port install p5-datetime-format-mail
}

install_prereqs_portage() {
    # For Gentoo.
    # Needed for buildbot
    $sudo emerge dev-python/virtualenv
    # Needed for fetching buildbot from git
    $sudo emerge dev-vcs/git
    # Needed for parsepatch.pl
    $sudo emerge dev-perl/DateTime-Format-Mail
}

install_prereqs() {
    if test x`which port` != x
    then
        install_prereqs_macports
    elif test x`which emerge` != x
    then
        # Check for Gentoo Prefix
        if emerge --info | grep "prefix"
        then
            sudo=
        else
            sudo=sudo
        fi
        install_prereqs_portage
    elif test x`which apt-get` != x
    then
        install_prereqs_apt
    else
        echo "unknown operating system" >&2
        exit 1
    fi
}

destroy() {
    if test -d $TOP
    then
        stop_master || true
        rm -rf $TOP || true
    fi
}

create_master() {
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
        # Work around recent regression, see http://thread.gmane.org/gmane.comp.python.buildbot.devel/7791
        git reset --hard dc63ce030fc5156cb84ad44516a6db6ae0238851
        # Fix bug that failed to preserve comment
        #patch -p1 < $SRC/buildbot-propagate-comment.patch
        # Hack out patch attachment, which still crashes
        patch -p1 < $SRC/buildbot-workaround-bug2091.patch
        # hack status page to show comment
        patch -p1 < $SRC/buildbot-show-comment.patch
        # hack to show more rows of grid
        patch -p1 < $SRC/buildbot-grid-length.patch
        export PIP_USE_MIRRORS=true
        pip install -emaster
        cd ..
    fi
    buildbot create-master master
    )
    cp parsepatch.pl $TOP/sandbox/bin/parsepatch.pl

    # Large patches cause problems without this.  Need on both sides,
    # see http://twistedmatrix.com/documents/current/core/howto/pb-limits.html
    sed -i.bak -e 's/SIZE_LIMIT =.*/SIZE_LIMIT = 2 * 1024 * 1024/' \
        $TOP/sandbox/lib/python2.?/site-packages/twisted/spread/banana.py
}

start_master() {
    (
    cd $TOP/sandbox
    . bin/activate
    cp $SRC/master.cfg $VIRTUAL_ENV/master
    buildbot start $VIRTUAL_ENV/master
    do_patchwatcher > $TOP/sandbox/master/patchwatcher.log 2>&1 &
    echo $! > $TOP/sandbox/master/patchwatcher.pid
    )
}

stop_master() {
    (
    cd $TOP/sandbox
    . bin/activate
    buildbot stop $VIRTUAL_ENV/master
    kill `cat $TOP/sandbox/master/patchwatcher.pid`
    )
}

# Shows how to bring up a demo master
demo() {
    destroy
    if test x`which virtualenv` = x
    then
        install_prereqs
    fi
    create_master
    start_master
}

#--------- Functions used to implement patchwatcher ---------

do_try() {
    (
    if test "$1" = ""
    then
        echo "need patch name"
        exit 1
    fi
    who=$2
    # The --properties flag uses comma as a delimiter, so we have to change all commas in comments to something else
    subject="`echo $3 | tr ',' ';'`"
    cd $TOP/sandbox
    . bin/activate
    # FIXME: import username and password from another file so
    # it doesn't show up in svn.  Must match those in master.cfg.
    # FIXME: Use real hostname for master.
    # Always use -p 1 for wine patches, since that's the project's convention.
    # Tell buildbot to apply patch against revision current as of now, since 
    # by the time it actually tries to apply the patch, it might already have
    # been committed!
    baserev=`wget -O- http://source.winehq.org/git/wine.git/patch | head -1 | awk '{print $2}'`
    buildbot try --baserev=$baserev $wait --who $who --comment "$subject"  --connect=pb --master=127.0.0.1:5555 --username=fred --passwd=trybot --diff=$1 -p 1
    )
}

# Try the oldest but-not-too-old not-yet-done patch series from source.winehq.org/patches
do_pulltry() {
    series=`perl $TOP/sandbox/bin/parsepatch.pl 1`
    if test "$series"
    then
        maxlen=`echo $series | wc -w`
        for len in `seq 1 $maxlen`
        do
            # Concatenate first len patches of the series
            > series.patch
            for id in `echo $series | tr ' ' '\012' | head -n $len`
            do
                cat cached_patches/cache-$id.patch >> series.patch
                subject="`grep '^Subject:' < cached_patches/cache-$id.patch | head -n 1 | sed 's/^Subject: //'`"
            done
            author_email=`grep '^From:' < series.patch | head -n 1 | sed 's/^From: //;s/.*<//;s/>.*//'`
            do_try `pwd`/series.patch $author_email "${id}: ${subject}"
        done
    fi
}

# Sit and test new patches forever
do_patchwatcher() {
    while true
    do
       do_pulltry || true
       # Launch at most one patch per minute
       sleep 60
    done
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
    destroy) destroy;;
    install_prereqs) install_prereqs;;
    create) create_master;;
    start) start_master;;
    stop) stop_master;;
    tail) tail -f $TOP/sandbox/master/twistd.log;;
    demo) demo;;
    try) do_try $1 $EMAIL "$SUBJECT"; shift;;
    *) usage ;;
    esac
done
