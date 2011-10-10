#!/bin/sh
# Start a wine buildbot slave
# Copyright 2011, Dan Kegel
# LGPL

set -e
#set -x

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
    # Let's start off with the basics...
    uname -sr | tr -d '\012'
    echo ", "

    if test x`which lsb_release` != x
    then
        lsb_release -d -s
    elif test x`which sw_vers` != x
    then
        sw_vers -productName
        echo " "
        sw_vers -productVersion
    fi | tr -d '\012'
}

system_audioinfo() {
    if test x`which pulseaudio` != x
    then
        pulseaudio --version | tr -d '\012'
    fi
    if test -r /proc/asound/version
    then
        echo ", "
        cat /proc/asound/version
    fi
}

system_cpuname() {
    if test -r /proc/cpuinfo
    then
        # Linux
        cat /proc/cpuinfo  | grep "model name" | uniq | sed 's/model name.: //'
    elif test x`uname -s` = xDarwin
    then
        # Mac
        sysctl -n machdep.cpu.brand_string
    else 
        # Works on FreeBSD, don't know about others
        sysctl -n hw.model
    fi
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
    if test x`which free` != x
    then
        free | awk '/Mem:/ {printf("%d\n", $2 / 1024); }'
    elif test x`which sysctl` != x
    then
        # Mac, freebsd
        sysctl -n hw.memsize | awk '{printf("%d\n", $0 / 1048576);}'
    fi
}

system_gpu() {
    # FIXME: do this portably
    glxinfo | egrep "OpenGL renderer string:|OpenGL version string" | sed 's/.*string: //'
}

system_info() {
    echo "cpu:   " `system_cpuname`
    echo "ram:   " `system_ram_megabytes` MB
    echo "os:    " `system_osname`
    echo "audio: " `system_audioinfo`
    echo "gpu:   " `system_gpu`
}

#----- Functions invoked by user when setting up or starting slave -----------

install_prereqs_apt() {
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

    # Needed to avoid gecko prompt
    sh ../install-gecko.sh
}

install_prereqs_macports() {
    # For Mac OS X with MacPorts.
    # Needed for buildbot
    sudo port install py-virtualenv
    # Needed to report on GPU type
    sudo port install glxinfo
    # Needed to apply patches
    sudo port install autoconf
    # Needed to make repeated builds of same files go faster
    sudo port install ccache
    # Needed to pass rpcrt4 tests
    sudo port install samba3 +universal
    # Needed to avoid gecko prompt
    sh ../install-gecko.sh
}

install_prereqs_portage() {
    # For Gentoo.  Other systems may differ.
    # Needed for buildbot
    $sudo emerge dev-python/virtualenv 
    # Needed to report on GPU type
    $sudo emerge x11-apps/mesa-progs
    # Needed to apply patches
    $sudo emerge sys-devel/autoconf
    # Needed to make repeated builds of same files go faster
    $sudo emerge dev-util/ccache
    # Needed to work around http://bugs.winehq.org/show_bug.cgi?id=28097
    #$sudo emerge ttf-mscorefonts-installer # Don't know where to get it...
    # Needed to pass rpcrt4 tests
    # Note: Gentoo Prefix does not have samba yet, so don't abort if package missing
    $sudo env USE="winbind" emerge net-fs/samba || true
    # Needed to avoid gecko prompt
    sh ../install-gecko.sh
    # linux x86 32 bit compatibility packages are only present on Linux x86_64 64 bit systems (and not e.g. on mac or solaris)
    case `uname -s`:`arch` in
    Linux:x86_64)
        $sudo emerge app-emulation/emul-linux-x86-baselibs app-emulation/emul-linux-x86-opengl app-emulation/emul-linux-x86-xlibs app-emulation/emul-linux-x86-medialibs app-emulation/emul-linux-x86-soundlibs
        ;;
    esac
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
        # don't fail if git branch -M fails
        patch -p1 < $SRC/buildbot-git-1.7.7.patch
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
    # Disable deprecation warnings on Mac (see
    # http://bugs.winehq.org/show_bug.cgi?id=16107)
    if test x`uname -s` = xDarwin
    then
        cflags="$cflags -Wno-error=deprecated-declarations"
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

    # If the source tree is changed at all, regenerate build system and protocol
    if test -n "`git status --porcelain | grep -v '^??'`"
    then
        git commit -a -m "commit so we can do make_makefiles"
        tools/make_makefiles

        # If make_requests didn't actually change the protocol, don't change the protocol number
        cp -p include/wine/server_protocol.h include/wine/server_protocol.h.bak
        tools/make_requests
        diff include/wine/server_protocol.h.bak include/wine/server_protocol.h || true
        if ! diff -u include/wine/server_protocol.h.bak include/wine/server_protocol.h | grep -v SERVER_PROTOCOL_VERSION | grep -v server_protocol.h | egrep '^[-+]'
        then
            cp -p include/wine/server_protocol.h.bak include/wine/server_protocol.h
        fi

        # Undo the git commit, but not the patches, so dotests.sh can tell what to test
        git reset 'HEAD^'

        # Generate ./configure and include/config.h.in
        autoreconf
    fi

    # Reuse configure cache between runs, saves 30 seconds
    configopts="--cache-file=../config-$buildwidth.cache"
    case $buildwidth in
    64) configopts="$configopts --enable-win64";;
    esac
    if test x`uname -s` = xDarwin
    then
        if test -d /opt/X11
        then
            configopts="$configopts --x-includes=/opt/X11/include --x-libraries=/opt/X11/lib"
        else
            configopts="$configopts --x-includes=/usr/X11/include --x-libraries=/usr/X11/lib"
        fi
    fi
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

    # When run in a normal locale, gcc inserts non-ascii characters into
    # its error message stream.  This causes a crash when the error messages
    # are inserted into the build failure email
    # File "buildbot/status/mail.py", line 520, in createEmail
    # text = msgdict['body'].encode(ENCODING)
    # exceptions.UnicodeDecodeError: 'ascii' codec can't decode byte 0xe2 
    #                                in position 557: ordinal not in range(128)
    # So set C locale when running make.
    # (Alternately, we could have our message formatter or error extractor
    # convert the unicode char into one that fits in ascii.)

    LANG=C make -j2 depend

    # If your hit rate per 'ccache -s' is too low, turn the log file on and look at it
    #export CCACHE_LOGFILE=/tmp/ccache.log
    # The ccache manpage explains when these are needed.  
    # Turning them on really helped on my e7300.
    export CCACHE_SLOPPINESS="file_macro,time_macros,include_file_mtime" 
    LANG=C make -j`system_numcpus`
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

# If system needs a reboot, refuse to run tests, since 
# kernel updates can cause 3d tests to fail if a
# proprietary driver is in use.
# FIXME: detect problem modes in non-Ubuntu/Debian buildslaves, too
if test -f /var/run/reboot-required
then
    # Sleep after message so slave has time to propagate message to master
    echo System needs reboot.  Shutting down buildslave.  Please reboot.
    sleep 15
    stop_slave
    exit 1
fi

# If system running in failsafe graphics, X probably crashed.
# FIXME: detect problem modes in non-Ubuntu/Debian buildslaves, too
if ps augxw | grep failsafeXServer | grep -v grep
then
    # Sleep after message so slave has time to propagate message to master
    echo X running in failsafe mode.  Shutting down buildslave.  Please reboot.
    sleep 15
    stop_slave
    exit 1
fi
if grep "Server aborting" /var/log/Xorg.log.0.old
then
    echo X server seems to have crashed.  Shutting down buildslave.  Please remove /var/log/Xorg.log.0.old and reboot.
    sleep 15
    stop_slave
    exit 1
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
