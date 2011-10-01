#!/bin/sh
# Start a wine buildbot slave
# Copyright 2011, Dan Kegel
# LGPL

set -e
set -x

TOP=$HOME/wineslave.dir

case `arch` in
i?86) geckoarch=x86;;
x86_64) geckoarch=x86_64;;
esac

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
    echo "   configure [COMPILER, e.g. 'ccache gcc']"
    echo "   build"
    echo "   test"
    echo "   heaptest"
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
    case `system_osname` in
    *buntu*|*ebian*)
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
        case `arch` in
        x86_64)
            sudo apt-get install libc6-dev-i386 ia32-libs
            ;;
        esac
        ;;
    esac

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

    if ! test -f $SRC/wine_gecko-1.3-$geckoarch-dbg.tar.bz2
    then
        wget http://downloads.sourceforge.net/wine/wine_gecko-1.3-$geckoarch-dbg.tar.bz2 -O $SRC/wine_gecko-1.3-$geckoarch-dbg.tar.bz2
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
    cp $SRC/wine_gecko-1.3-$geckoarch-dbg.tar.bz2 $TOP/sandbox/bin
    )

    # Large patches cause problems without this.  Need on both sides,
    # see http://twistedmatrix.com/documents/current/core/howto/pb-limits.html
    sed -i.bak -e 's/SIZE_LIMIT =.*/SIZE_LIMIT = 2 * 1024 * 1024/' \
        $TOP/sandbox/lib/python2.?/site-packages/twisted/spread/banana.py

    echo "Filling in $TOP/sandbox/slave/info/host with following info:"
    system_info
    system_info > $TOP/sandbox/slave/info/host

    echo "Please put your name and email address in $TOP/sandbox/slave/info/admin !"
}

start_slave() {
    (
    cd $TOP/sandbox
    . bin/activate

    # in case someone did 'stop; svn up; start'
    cp $SRC/wineslave.sh $TOP/sandbox/bin/wineslave.sh
    cp $SRC/dotests.sh $TOP/sandbox/bin/dotests.sh
    cp $SRC/dotests_blacklist.txt $TOP/sandbox/bin/
    chmod +x $TOP/sandbox/bin/wineslave.sh
    rm -f $TOP/sandbox/bin/*.patch
    cp $SRC/*-ignore-*.patch $TOP/sandbox/bin
    cp $SRC/*-placate-*.patch $TOP/sandbox/bin
    gcc $SRC/alarum.c -o $TOP/sandbox/bin/alarum

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
    if test x`which ccache` = x
    then
        install_prereqs
    fi
    create_slave localhost:9989 example-slave pass
    start_slave
}

#--------- Functions used while slave is running; invoked by master.cfg ---------
#---- Current directory is the top of the wine tree for the current builder -----

# Apply patches needed to skip flaky tests
do_patch() {
    for p in $SRC/*-ignore-*.patch $SRC/*-placate-*.patch
    do
        if test -f $p
        then
            echo $p
            # commit them so they don't show up in list of modified files
            # The local repository goes away after each test, it's not a permanent thing
            # Hopefully this will not also commit the user's patch, which we
            # rely to be uncommitted so dotests.sh can detect what user changed
            awk '/^\+\+\+/ {print $2}' < $p | sed 's,^[^/]*/,,' > pfiles
            git apply $p
            git commit -m "committing $p" `cat pfiles`
        fi
    done
}

do_configure() {
    cat > hello.c <<__EOF__
#include <stdio.h>

int main(void)
{
    printf("Hello, world?\n");
    return 0;
}
__EOF__

    # If user specified a compiler, use it, else default to "ccache gcc"
    case "$1" in
    "") CC="ccache gcc";;
    *)  CC="$1";;
    esac

    # Figure out whether this is a 32 or 64 bit build
    # FIXME: this should also depend on commandline
    case `arch` in
    x86_64) buildwidth=64 ;;
    *)      buildwidth=32 ;;
    esac

    # Verify that compiler works
    $CC hello.c -o hello
    if [ "`./hello`" != "Hello, world?" ]
    then
        rm -f hello
        echo "compiler failed to produce a working executable."
        exit 1
    fi

    # Figure out right compiler options
    cflags="-g -O0"
    # http://bugs.winehq.org/show_bug.cgi?id=28275 shows wine's not
    # ready for -Werror on 64 bits
    if test $buildwidth = 32 && $CC -Werror -c hello.c -o hello
    then
        cflags="$cflags -Werror"
    fi
    # gcc-4.6 produces warnings that haven't been preened out of wine's tree yet, so disable them
    if $CC -Werror -Wno-unused-but-set-variable hello.c -o hello
    then
        cflags="$cflags -Wno-unused-but-set-variable"
    fi
    if $CC -Werror -Wno-unused-but-set-parameter hello.c -o hello
    then
        cflags="$cflags -Wno-unused-but-set-parameter"
    fi
    rm -f hello || true

    git commit -a -m "commit so we can do make_makefiles"
    tools/make_makefiles
    tools/make_requests

    # Generate ./configure
    autoconf

    # Reuse configure cache between runs, saves 30 seconds
    configopts="--cache-file=../config-$buildwidth.cache"
    case $buildwidth in
    64) configopts="$configopts --enable-win64";;
    esac
    if ! ./configure $configopts CC="$CC" CFLAGS="$cflags"
    then
        # If cache failed, clean it out and try again
        rm ../config-$buildwidth.cache
        ./configure $configopts CC="$CC" CFLAGS="$cflags"
    fi
}

do_build() {
    # Try to work around http://bugs.winehq.org/show_bug.cgi?id=28373 
    # "make depend" with -j higher than 4 seems to be dangerous, so let's do it explicitly here.
    # (-j2 is about 20 seconds faster than -j1, and all my build machines are dual-core or
    # better, so let's use -j2 for make depend.)
    make -j2 depend

    # If your hit rate per 'ccache -s' is too low, turn the log file on and look at it
    #export CCACHE_LOGFILE=/tmp/ccache.log
    # The ccache manpage explains when these are needed.  
    # Turning them on really helped on my e7300.
    export CCACHE_SLOPPINESS="file_macro,time_macros,include_file_mtime" 
    make -j`system_numcpus`
}

do_test() {
    cp $SRC/wine_gecko-1.3-$geckoarch-dbg.tar.bz2 .
    # Get a fresh copy every single time?
    (
         rm -rf tmp-svn
         mkdir tmp-svn
         cd tmp-svn
         if svn export https://winezeug.googlecode.com/svn/trunk/buildbot/dotests_blacklist.txt
         then
             cp dotests_blacklist.txt ${SRC}
         fi
    )
    PATH="${SRC}:$PATH" sh $SRC/dotests.sh goodtests
}

#--------- Main program ---------------------------------------------------------

SRC=`dirname $0`
SRC=`cd $SRC; pwd`
echo wineslave.sh started in directory `pwd` with arguments $@

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
    configure)
        # defaults to "ccache gcc", but only if last verb on commandline
        do_configure $1
        # bash bug: shift || true fails?!, must avoid doing it if last parameter
        if test "$1"
        then
            shift || true
        fi
        ;;
    build) do_build;;
    test) do_test;;
    heaptest) 
        (
            WINEDEBUG=warn+heap 
            export WINEDEBUG
            do_test
        );;
    demo) demo;;
    *) echo "Invalid argument $arg"; usage;;
    esac
done
