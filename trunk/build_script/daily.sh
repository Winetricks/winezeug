#!/bin/sh
#
# Wine build-helper script
#
# Copyright 2009 Austin English <austinenglish@gmail.com>
#
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice, this list of
#  conditions and the following disclaimer.
#
#  2. Redistributions in binary form must reproduce the above copyright notice, this list of
#  conditions and the following disclaimer in the documentation and/or other materials
#  provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR
#  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
#  AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
#  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
#  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
#  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
#
# To do:
# handle errors gracefully with proper exits and error messages
# add more Linux distro support

# Now some common definitions:

# Where your wine-git directory is located. Most people have it in
# $HOME/wine-git, but I know some cranky bastard is going to put it
# elsewhere...
WINEGIT=${WINEGIT:-$HOME/wine-git}

# The directory where the script will put its temp files.
WINETESTDIR=${WINETESTDIR:-$HOME/.winetest}

# This WINEPREFIX is for running the conformance tests. If you want to use a
# different one, change it here or override the environmental variable.
WINEPREFIX=${WINEPREFIX:-$WINETESTDIR/wineprefix}

# The tree for building Wine for the conformance tests. This will be removed and
# recreated unless --no-newtree is specified.
WINETESTGIT=${WINETESTGIT:-$WINETESTDIR/winesrc}

# Set your name here. It will be used to submit test data. If none is given, your username will be used.
NAME=${NAME:-`whoami`}

# Set your machine name here. Again, used for the test data. If none is given, your hostname is used.
MACHINE=${MACHINE:-`uname -n`}

# This is the time between retrying to fetch the updated git tree. Default is 30 minutes. Adjust to your taste.
# Be sure you put it in seconds. Not all OS's support the d/h/m options (OpenSolaris, I'm looking at you!)
WAITTIME=${WAITTIME:-1800}

die() {
  echo "$@"
  exit 1
}

export WINE=$WINETESTGIT/wine
export WINESERVER=$WINETESTGIT/server/wineserver
export WINEPREFIX=$WINEPREFIX
export WINEGITURL="git://source.winehq.org/git/wine.git"

if [ `which ccache` ]
    then
        export CC="ccache gcc"
else
        export CC="gcc"
fi

set -e

# First, find out the OS we're on. This way, we can have a single portable, build script.

OS=`uname -s`
# TODO: Differentiate between Solaris and OpenSolaris here...not sure how though :-/
if [ $OS = 'SunOS' ] || [ $OS = 'Solaris' ]
    then
        export CFLAGS="-I/usr/sfw/include -I/usr/X11/include -g" 
        export CPPFLAGS="-I/usr/sfw/include" 
        export CC="/usr/gnu/bin/cc" 
        export LDFLAGS="-L/usr/sfw/lib -R/usr/sfw/lib -L/usr/X11/lib -R/usr/X11/lib" 
        export LD="/usr/gnu/bin/ld" 
        export PATH="/usr/gnu/bin:/usr/bin:/usr/X11/bin:/usr/sbin:/sbin:/opt/csw/bin/:/usr/ccs/bin:/usr/sfw/bin:/usr/local/bin"
        export CONFIGUREFLAGS="--without-ldap --without-capi"
        CORES=$(/usr/sbin/psrinfo| grep -c on-line)
elif [ $OS = 'Linux' ] || [ $OS = 'GNU/Linux' ]
    then
        export CFLAGS="-Wno-unused"
        CORES=$(cat /proc/cpuinfo | grep -c processor)
        # Are we on 64-bit?
        if [ "`uname -m`" = "x86_64" ]
            then
            # Are we on Ubuntu?
            if [ "`lsb_release -i -s`" = "Ubuntu" ]
                then
                    export CONFIGUREFLAGS="--without-mpg123"
            fi
        else
            echo "Most Linux distros should build fine out of the box."
            echo "If not, please notifiy the maintainer to add your build script here."
        fi
# PC-BSD or FreeBSD?
elif [ $OS = 'FreeBSD' ] && [ "`which pbreg`" ]
    then
        export CPPFLAGS="-I/PCBSD/local/include"
        export LDFLAGS="-L/PCBSD/local/lib"
        CORES=$(/sbin/sysctl -n hw.ncpu)
elif [ $OS = 'FreeBSD' ]
    then
        export CPPFLAGS="-I/usr/local/include"
        export LDFLAGS="-L/usr/local/lib"
        CORES=$(/sbin/sysctl -n hw.ncpu)
elif [ $OS = 'Darwin' ]
    then
        # BUILD_DIR is the directory where you've built and installed wine's dependencies...OS X's built in one's are
        # very broken for wine. Use install-osx-deps.sh from Winezeug to install this stuff in the right place.
        export BUILD_DIR=$HOME/.winedeps
        export CPPFLAGS="-I$BUILD_DIR/usr/include"
        export CFLAGS="-I$BUILD_DIR/usr/include"
        export LDFLAGS="-L$BUILD_DIR/usr/lib"
        export PATH=$PATH:"$BUILD_DIR/usr/bin"
        export PKG_CONFIG_PATH="$BUILD_DIR/usr/lib/pkgconfig"
        export CONFIGUREFLAGS='--disable-win16 --without-hal --without-capi'
        CORES=$(/usr/sbin/sysctl -n hw.ncpu)
elif [ $OS = 'NetBSD' ]
    then
        echo "This is untested...going from memory"
        export CFLAGS="-O2 -I/usr/pkg/include -I/usr/include -I/usr/pkg/include/freetype2 -I/usr/X11R6/include"
        export CPPFLAGS="-I/usr/pkg/include -I/usr/include -I/usr/pkg/include/freetype2 -I/usr/X11R6/include"
        export LDFLAGS="-L/usr/pkg/lib -Wl,-R/usr/pkg/lib -L/usr/lib -Wl,-R/usr/lib -L/usr/X11R6/lib -Wl,-R/usr/X11R6/lib"
        CORES=$(/sbin/sysctl -n hw.ncpu)
elif [ $OS = 'OpenBSD' ]
    then
        export CFLAGS="-I/usr/local/include -I/usr/local/include/libpng"
        export LDFLAGS="-lm -lz -lcrypto -L/usr/local/lib"
        export X_EXTRA_LIBS="-lXau -lXdmcp"
        export CPPFLAGS="-I/usr/local/include"
        #FIXME: CORES
else
    echo "Your OS is not supported by this build script. Please e-mail the maintainer if you get this message."
    exit 1
fi

# Make sure wget is available:
if [ `which wget` ]
    then
        GET="wget"
# If not, use ftp. TODO: Find a better fix. This doesn't work on Ubuntu's ftp, possibly others. The only reason
# to use this is for machines that don't have wget. The only ones I've seen that on is the BSD's, and this works fine there.
elif [ `which curl` ]
    then
        GET="curl -L -O"
elif [ `which ftp` ]
    then
        GET="ftp"
else
    echo "You don't have wget, curl or ftp installed. I can't download needed files. Please report this as a bug."
    exit 1
fi

# Fetch an updated tree
newtree() {
# Make sure the user has a git tree. If not, initialize (a small) one for them:
if [ ! -d "$WINEGIT" ]
    then
        git clone --depth 1 "$WINEGITURL" "$WINEGIT"
else
    cd "$WINEGIT"
    git show > /dev/null 2>&1 || die "$WINEGIT exists but is not a git directory. Exiting!"

    # This is used for our loop to check for updated git tree.
    TREESTATUS=0
    while [ $TREESTATUS = "0" ]
    do
        echo "Attempting to fetch updated tree." &&
        # Should perhaps be [::alphanum::] instead of '.'?
        git fetch -v 2>&1 | grep ".......\.\........\ \ master" && break
        sleep $WAITTIME
    done
fi
}

rebase_tree() {
# Apply the updates to the tree.
# NOTE: This is not always safe, so it is not enabled by default.
# Use --rebase-tree to enable it
git rebase origin
}

clone_tree() {
# Clone a copy of the user's git tree from $WINEGIT to $WINETESTGIT
git clone --reference "$WINEGIT" "$WINEGITURL" "$WINETESTGIT"
}

# If our build fails :'(
build_failed() {
echo "$BUILDNAME build failed for some reason...Investigate manually you lazy bastard!"
exit 1
}

# TODO: sed/grep -v out visibility attribute/ignored return value errors, then wc -l error/warnings lines.
# From there, we can store $WARNINGS_PREDICTED in each OS above, and complain if it doesn't match.
# This shouldn't be used on Ubuntu right now, until the "ignoring return value" problem is fixed.
# TODO: determine if logs are wanted, and if so, store in buildlog-date.txt
build() {
echo "Starting $BUILDNAME build." && 
echo "Running configure." && ./configure --disable-tests $CONFIGUREFLAGS 1>/dev/null 2>&1 &&
echo "Running make depend." && make -j$CORES depend 1>/dev/null 2>&1 &&
echo "Running make." && make -j$CORES 1>/dev/null 2>&1 &&
echo "$BUILDNAME build was fine. Coolio"
}

# Test functions here...

enable_virtual_desktop() {
echo "Enabling virtual desktop"
cat > /tmp/virtualdesktop.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"

[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"="800x600"
_EOF_
echo "Importing registry key"
$WINE regedit /tmp/virtualdesktop.reg
echo "sleeping for 10 seconds...regedit bug?"
sleep 10s
}

# TODO: get winetest-SHA1SUM. If not available, wait/exit?
get_tests_32() {
    rm -rf winetest-*.exe ;
    $GET http://test.winehq.org/builds/winetest-latest.exe
}

get_tests_64() {
    rm -rf winetest64-*.exe ;
    $GET http://test.winehq.org/builds/winetest64-latest.exe
}

# FIXME: Should be more generic for gecko version, and maybe should support using 
# the debug version of gecko? Should possibly cleanup the gecko download? 
# For now, leave it, to save bandwidth. I'm deleting it in my wrapper script afterward...

# FIXME: Should probably sha1sum it to ensure correct download...
get_gecko() (
    mkdir -p ../gecko
    if [ -f ../gecko/wine_gecko-1.0.0-x86.cab ]
        then
            break
    elif [ -f /usr/local/share/wine/gecko/wine_gecko-1.0.0-x86.cab ]
        then
            cp /usr/local/share/wine/gecko/wine_gecko-1.0.0-x86.cab ../gecko/
    elif [ -f /usr/gecko/wine_gecko-1.0.0-x86.cab ]
        then
            cp /usr/share/wine/gecko/wine_gecko-1.0.0-x86.cab ../gecko/
    else
        $GET http://downloads.sourceforge.net/wine/wine_gecko-1.0.0-x86.cab
        mv wine_gecko-1.0.0-x86.cab ../gecko/
    fi
)

preptests() {
    $WINESERVER -k || true
    rm -rf $WINEPREFIX || true
    $WINE wineboot > /dev/null 2>&1 || exit 1
    sh $WINETESTDIR/winetricks nocrashdialog
}

# TODO: fix to use the SHA1SUM as well.
runtests() {
    length=`eval echo "$NAME-$MACHINE$TESTNAME" | wc -m`
    # The newline character counts as a charcter to wc, but not cut:
    if [ $length -gt 21 ]
        then
            echo "Your tag name is too long, trimming it down to 20 characters"
            tag=`eval echo $NAME-$MACHINE$TESTNAME | cut -c 1-20`
    else
        tag="$NAME-$MACHINE$TESTNAME"
    fi
    
    echo "About to start $tag test run. Expect no output for a while..." &&
    $WINE $TESTBINARY -c -t $tag 1>/dev/null 2>&1 &&
    rm -rf $WINEPREFIX
}

all_test() {
WINEDEBUG="+all"
TESTNAME="-all"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
runtests
}

alsa_test() {
WINEDEBUG=""
TESTNAME="-alsa"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks alsa
runtests
}

audioio_test() {
WINEDEBUG=""
TESTNAME="-audioio"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks audioio
runtests
}

build_regular() {
BUILDNAME=regular
CONFIGUREFLAGS=${CONFIGUREFLAGS}""
build || build_failed
}

build_nowin16() {
BUILDNAME=nowin16
CONFIGUREFLAGS=${CONFIGUREFLAGS}" --disable-win16"
build || build_failed
}

build_werror() {
BUILDNAME=werror
export CFLAGS="-Werror -g"
build || build_failed
}

build_win64() {
BUILDNAME=win64
CONFIGUREFLAGS=${CONFIGUREFLAGS}" --enable-win64"
build || build_failed
}

backbuffer_test() {
WINEDEBUG=""
TESTNAME="-bckbuf"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks backbuffer
runtests
}

coreaudioio_test() {
WINEDEBUG=""
TESTNAME="-all"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks coreaudioio
runtests
}

ddr_opengl_test() {
WINEDEBUG=""
TESTNAME="-ddr-opengl"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks ddr=opengl
runtests
}

esound_test() {
WINEDEBUG=""
TESTNAME="-esound"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks esound
runtests
}

fbo_test() {
WINEDEBUG=""
TESTNAME="-fbo"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks fbo
runtests
}

heap_test() {
WINEDEBUG="warn+heap"
TESTNAME="-heap"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
runtests
}

jack_test() {
WINEDEBUG=""
TESTNAME="-jack"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks jack
runtests
}

message_test() {
WINEDEBUG="+message"
TESTNAME="-message"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
runtests
}

multisampling_test() {
WINEDEBUG=""
TESTNAME="-mltsmp"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks multisampling=enabled
runtests
}

nas_test() {
WINEDEBUG=""
TESTNAME="-nas"
export WINEDEBUG
export TESTNAME
preptests
sh winetricks nas
runtests
}

nogecko_test() {
WINEDEBUG=""
TESTNAME="-nogecko"
export WINEDEBUG
export TESTNAME
preptests_nogecko
disable_gecko
runtests
}

noglsl_test() {
WINEDEBUG=""
TESTNAME="-noglsl"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks glsl-disable
runtests
}

nowin16_test() {
WINEDEBUG=""
TESTNAME="-nowin16"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
build_nowin16
preptests
runtests
}

oss_test() {
WINEDEBUG=""
TESTNAME="-oss"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks oss
runtests
}

pbuffer_test() {
WINEDEBUG=""
TESTNAME="-pbuffer"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks pbuffer
runtests
}

regular_test() {
WINEDEBUG=""
TESTNAME=""
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
runtests
}

relay_test() {
WINEDEBUG="+relay"
TESTNAME="-relay"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
runtests
}

rtlm_disabled_test() {
WINEDEBUG=""
TESTNAME="-no-rtlm"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks rtlm=disabled
runtests
}

rtlm_readdraw_test() {
WINEDEBUG=""
TESTNAME="-readtex"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks rtlm=readdraw
runtests
}

rtlm_readtex_test() {
WINEDEBUG=""
TESTNAME="-readtex"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks rtlm=readtex
runtests
}

rtlm_texdraw_test() {
WINEDEBUG=""
TESTNAME="-texdraw"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks rtlm=texdraw
runtests
}

rtlm_textex_test() {
WINEDEBUG=""
TESTNAME="-textex"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
sh $WINETESTDIR/winetricks rtlm=textex
runtests
}

seh_test() {
WINEDEBUG="+seh"
TESTNAME="-seh"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
runtests
}

virtual_desktop_test() {
WINEDEBUG=""
TESTNAME="-virtdesktop"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
preptests
enable_virtual_desktop
runtests
}

werror_test() {
WINEDEBUG=""
TESTNAME="-werror"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
build_werror
preptests
runtests
}

win64_test() {
WINEDEBUG=""
TESTNAME="-x64"
TESTBINARY="winetest64-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
build_win64
preptests
runtests
}

with64_test() {
WINEDEBUG=""
TESTNAME="-with64"
TESTBINARY="winetest-latest.exe"
export WINEDEBUG
export TESTNAME
export TESTBINARY
WINE=wine preptests
WINE=$WINETESTDIR/install/bin/wine32 runtests
}

#######################################################
##    Now to use the functions :-)
#######################################################

usage() {
echo "This script is used for Wine testing. By default, it will:"
echo "1) update your git tree"
echo "2) Build (32-bit) Wine"
echo "3) Download winetest.exe"
echo "4) Runs winetest.exe, without any special options, and submits the results"
echo ""
echo "The script, however, has many more options:"
echo "--no-newtree - Disables updating your git tree."
echo "--rebase-tree - Run 'git rebase origin' in $WINEGIT, rather than making a new temp tree"
echo "--no-tests - Disables downloading/running winetest.exe"
echo "--no-regular - Skip running winetest.exe without special options"
echo "--alldebug - Runs winetest.exe with WINEDEBUG=+all"
echo "--alsa - Runs winetest.exe with ALSA sound system"
echo "--audioio - Runs winetest.exe with AudioIO sound system"
echo "--backbuffer - Runs winetest.exe with offscreen rendering mode set to backbuffer"
echo "--ddr-opengl - Runs winetest.exe with DirectDrawRenderer set to OpenGL"
echo "--esound - Runs winetest.exe with ESound sound system"
echo "--fbo - Runs winetest.exe with offscreen rendering mode set to FBO"
echo "--heap - Runs winetest.exe with WINEDEBUG=+heap"
echo "--jack - Runs winetest.exe with JACK sound system"
echo "--message - Runs winetest.exe with WINEDEBUG=+message"
echo "--multisamping - Runs winetest.exe with multisampling enabled"
echo "--no-glsl - Runs winetest.exe with glsl disabled"
echo "--no-win16 - Builds Wine without win16 support and runs winetest.exe"
echo "--pbuffer - Runs winetest.exe with offscreen rendering mode set to pbuffer"
echo "--rtlm-disabled - Runs winetest.exe with RenderTargetLockMode disabled"
echo "--rtlm-readdraw - Runs winetest.exe with RenderTargetLockMode set to readdraw"
echo "--rtlm-readtex - Runs winetest.exe with RenderTargetLockMode set to readtex"
echo "--rtlm-texdraw - Runs winetest.exe with RenderTargetLockMode set to texdraw"
echo "--rtlm-textex - Runs winetest.exe with RenderTargetLockMode set to textex"
echo "--seh - Runs winetest.exe with WINEDEBUG=+seh"
echo "--virtual-desktop - Runs winetest.exe in a virtual desktop"
echo "--werror - Builds Wine with -Werror and runs winetest.exe"
echo "--win64 - Builds 64-bit Wine and runs winetest64.exe"
echo "--with64 - Builds 32-bit Wine alongside 64-bit Wine, then runs winetest.exe"
echo "You probably don't need any of the special options, though"
echo "The exception is --no-newtree in case you want to run tests again without waiting for a git push."
}

# There's probably a cleaner way to do this, but I'm lazy and I'll do it how I know
# Setting the variables here, to avoid errors below.
NEWTREE=0
REBASE_TREE=0
NOTESTS=0
NOREGULAR_TEST=0
ALLDEBUG_TEST=0
ALSA_TEST=0
AUDIOIO_TEST=0
BACKBUFFER_TEST=0
COREAUDIO_TEST=0
DDR_OPENGL_TEST=0
ESOUND_TEST=0
FBO_TEST=0
HEAP_TEST=0
JACK_TEST=0
MESSAGE_TEST=0
MULTISAMPLING_TEST=0
NOGLSL_TEST=0
NOWIN16_TEST=0
OSS_TEST=0
PBUFFER_TEST=0
RTLM_DISABLED=0
RTLM_READDRAW=0
RTLM_READTEX=0
RTLM_TEXDRAW=0
RTLM_TEXTEX=0
SEH_TEST=0
VD_TEST=0
WERROR_TEST=0
WIN64_TEST=0
WITH64_TEST=0

while test "$1" != ""
do
    case $1 in
    -v) set -x;;
    --no-newtree) export NEWTREE=1;;
    --rebase-tree) export REBASE_TREE=1; export WINE=$WINEGIT/wine; export WINESERVER=$WINEGIT/server/wineserver;;
    --no-tests) export NOTESTS=1;;
    --no-regular) export NOREGULAR_TEST=1;;
    --alldebug) export ALLDEBUG_TEST=1;;
    --alsa) export ALSA_TEST=1;;
    --audioio) export AUDIOIO_TEST=1;;
    --backbuffer) export BACKBUFFER_TEST=1;;
    --coreaudio) export COREAUDIO_TEST=1;;
    --ddr-opengl) export DDR_OPENGL_TEST=1;;
    --esound) export ESOUND_TEST=1;;
    --fbo) export FBO_TEST=1;;
    --heap) export HEAP_TEST=1;;
    --jack) export JACK_TEST=1;;
    --message) export MESSAGE_TEST=1;;
    --multisampling) export MULTISAMPLING_TEST=1;;
    --nas) export NAS_TEST=1;;
    --no-gecko) export NOGECKO_TEST=1;;
    --no-glsl) export NOGLSL_TEST=1;;
    --no-win16) export NOWIN16_TEST=1;;
    --oss) export OSS_TEST=1;;
    --pbuffer) export PBUFFER_TEST=1;;
    --rtlm-disabled) export RTLM_DISABLED=0;;
    --rtlm-readdraw) export RTLM_READDRAW=0;;
    --rtlm-readtex) export RTLM_READTEX=1;;
    --rtlm-texdraw) export RTLM_TEXDRAW=1;;
    --rtlm-textex) export RTLM_TEXTEX=1;;
    --seh) export SEH_TEST=1;;
    --virtual-desktop) export VD_TEST=1;;
    --werror) export WERROR_TEST=1;;
    --win64|--win-64|--wine64|--wine-64) export WIN64_TEST=1;;
    --with64|--with-64) export WITH64_TEST=1;;
    *) echo Unknown arg $1; usage; exit 1;;
    esac
    shift
done

# Start with a clean slate:
rm -rf $WINETESTDIR
mkdir -p $WINETESTDIR

# Get winetricks, used in below tests:
$GET "http://winezeug.googlecode.com/svn/trunk/winetricks" &&
mv winetricks $WINETESTDIR

# Get new tree, if it wasn't disabled.
if [ $NEWTREE = 1 ]
    then 
        echo "not updating git tree"
else
    newtree
fi

# Rebase tree, if desired. Otherwise, clone a copy of the tree for our tests.
# Either way, cd to the right directory.
if [ $REBASE_TREE = 1 ]
    then
        cd "$WINEGIT"
        rebase_tree
else
    clone_tree
    cd "$WINETESTGIT"
fi

# Anything requiring a special build goes here, that way when we recompile for
# For the regular tests, the tree is left is a 'vanilla' state.
# Currently, just win16/win64. But could be used for other things, e.g., disabling dlls.

if [ $NOWIN16_TEST = 1 ]
    then 
        nowin16_test
fi

if [ $WERROR_TEST = 1 ]
    then
        werror_test
fi

if [ $WIN64_TEST = 1 ]
    then 
        get_tests_64
        win64_test
fi

if [ $WITH64_TEST = 1 ]
    then
        WINETESTGIT=$WINETESTDIR/wine64 clone_tree
        # FIXME: Should probably be a more proper build function, a la above.
        # Though, right now, 64-bit only works on Linux, so not a huge deal.
        cd $WINETESTDIR/wine64
        ./configure --enable-win64 --disable-tests --prefix=$WINETESTDIR/install
        make -j$CORES depend
        make -j$CORES
        make install
        
        WINETESTGIT=$WINETESTDIR/wine32 clone_tree
        cd $WINETESTDIR/wine32
        ./configure --with-wine64=$WINETESTDIR/wine64 --disable-tests --without-mpg123 --prefix=$WINETESTDIR/install
        make -j$CORES depend
        make -j$CORES
        make install
        
        get_tests_32
        export WINE=$WINETESTDIR/install/bin/wine32
        export WINESERVER=$WINETESTDIR/install/bin/wineserver
        with64_test
fi

# Build Wine
build_regular

# Exit early, if tests aren't to be run:
if [ $NOTESTS = 1 ]
    then
        echo "tests aren't running, exiting"; exit
fi

# Make sure we have gecko:
get_gecko
get_tests_32

if [ $NOREGULAR_TEST = 1 ]
    then
        echo "Not running regular test."
else
    regular_test
fi

if [ $ALLDEBUG_TEST = 1 ]
    then
        all_test
fi

if [ $ALSA_TEST = 1 ]
    then
        alsa_test
fi

if [ $AUDIOIO_TEST = 1 ]
    then
        audioio_test
fi

if [ $BACKBUFFER_TEST = 1 ]
    then
        backbuffer_test
fi

if [ $COREAUDIO_TEST = 1 ]
    then
        coreaudio_test
fi

if [ $DDR_OPENGL_TEST = 1 ]
    then
        ddr_opengl_test
fi

if [ $ESOUND_TEST = 1 ]
    then
        esound_test
fi

if [ $FBO_TEST = 1 ]
    then
        fbo_test
fi

if [ $HEAP_TEST = 1 ]
    then
        heap_test
fi

if [ $JACK_TEST = 1 ]
    then
        jack_test
fi

if [ $MESSAGE_TEST = 1 ]
    then message_test
fi

if [ $MULTISAMPLING_TEST = 1 ]
    then
        multisampling_test
fi

if [ $NAS_TEST = 1 ]
    then
        nas_test
fi

if [ $NOGECKO_TEST = 1 ]
    then
        nogecko_test
fi

if [ $NOGLSL_TEST = 1 ]
    then
        noglsl_test
fi

if [ $OSS_TEST = 1 ]
    then
        oss_test
fi

if [ $PBUFFER_TEST = 1 ]
    then
        pbuffer_test
fi


if [ $RTLM_DISABLED = 1 ]
    then
        rtlm_disabled_test
fi

if [ $RTLM_READDRAW = 1 ]
    then
        rtlm_readdraw_test
fi
    
if [ $RTLM_READTEX = 1 ]
    then
        rtlm_readtex_test
fi
    
if [ $RTLM_TEXDRAW = 1 ]
    then
        rtlm_texdraw_test
fi
    
if [ $RTLM_TEXTEX = 1 ]
    then
        rtlm_textex_test
fi
    

if [ $SEH_TEST = 1 ]
    then
        seh_test
fi

if [ $VD_TEST = 1 ]
    then
        virtual_desktop_test
fi

# Cleanup
rm -rf /tmp/*.reg $WINEPREFIX winetrick* $WINETESTDIR

exit
