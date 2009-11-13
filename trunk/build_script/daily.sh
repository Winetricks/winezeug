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
# Add support for first time git initialization.

# Now some common definitions:

# This WINEPREFIX is for running the conformance tests. If you want to use a
# different one, change it here or override the environmental variable.
WINEPREFIX=${WINEPREFIX:-$HOME/.winetest}

# Set your name here. It will be used to submit test data. If none is given, your username will be used.
NAME=${NAME:-`whoami`}

# Set your machine name here. Again, used for the test data. If none is given, your hostname is used.
MACHINE=${MACHINE:-`uname -n`}

# This is the time between retrying to fetch the updated git tree. Default is 30 minutes. Adjust to your taste.
# Be sure you put it in seconds. Not all OS's support the d/h/m options (OpenSolaris, I'm looking at you!)
WAITTIME=1800

die() {
  echo "$@"
  exit 1
}

export WINE=`pwd`/wine

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
elif [ $OS = 'Linux' ] || [ $OS = 'GNU/Linux' ]
    then
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
elif [ $OS = 'FreeBSD' ]
    then
        export CPPFLAGS="-I/usr/local/include"
        export LDFLAGS="-L/usr/local/lib"
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
elif [ $OS = 'NetBSD' ]
    then
        echo "This is untested...going from memory"
        export CFLAGS="-O2 -I/usr/pkg/include -I/usr/include -I/usr/pkg/include/freetype2 -I/usr/X11R6/include"
        export CPPFLAGS="-I/usr/pkg/include -I/usr/include -I/usr/pkg/include/freetype2 -I/usr/X11R6/include"
        export LDFLAGS="-L/usr/pkg/lib -Wl,-R/usr/pkg/lib -L/usr/lib -Wl,-R/usr/lib -L/usr/X11R6/lib -Wl,-R/usr/X11R6/lib"
elif [ $OS = 'OpenBSD' ]
    then
        export CFLAGS="-I/usr/local/include -I/usr/local/include/libpng"
        export LDFLAGS="-lm -lz -lcrypto -L/usr/local/lib"
        export X_EXTRA_LIBS="-lXau -lXdmcp"
        export CPPFLAGS="-I/usr/local/include"
else
    echo "Your OS is not supported by this build script. Please e-mail the maintainer if you get this message."
    exit 1
fi

# Make sure wget is available:
if [ `which wget` ]
    then
        GET="wget "$1""
# If not, use ftp. TODO: Find a better fix. This doesn't work on Ubuntu's ftp, possibly others. The only reason
# to use this is for machines that don't have wget. The only ones I've seen that on is the BSD's, and this works fine there.
elif [ `which curl` ]
    then
        GET="curl -o `basename "$1"` $1"
elif [ `which ftp` ]
    then
        GET="ftp "$1""
else
    echo "You don't have wget, curl or ftp installed. I can't download needed files. Please report this as a bug."
    exit 1
fi

# Fetch an updated tree

newtree() {

# make sure we're in a git tree to start with:
git show > /dev/null 2>&1 || die "Not in a git tree! Initializing a fresh git tree isn't yet supported."

# TODO: don't force a hard reset for those that don't want it. 'git checkout -f origin' should be just as effective 
echo "Resetting git tree to origin." && git reset --hard origin &&

# This is used for our loop to check for updated git tree. TODO: Is there a cleaner way to do this?
TREESTATUS=0
while [ $TREESTATUS = "0" ]
do
# TODO: This fails if the the git site can't be reached. Need to adjust appropriately.
  echo "Attempting to fetch updated tree." && git fetch ;
  git rebase origin 2>&1 | grep "Current branch HEAD is up to date" || break
  sleep $WAITTIME
done
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
echo "Running configure." && ./configure $CONFIGUREFLAGS 1>/dev/null 2>&1 &&
echo "Running make depend." && make depend 1>/dev/null 2>&1 &&
echo "Running make." && make 1>/dev/null 2>&1 &&
echo "$BUILDNAME build was fine. Coolio"
}

# Test functions here...

disable_gecko() {
cat > /tmp/disable_gecko.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\MSHTML]
"GeckoUrl"=-
_EOF_

./wine regedit /tmp/disable_gecko.reg
sleep 10s
}

disable_glsl() {
cat > /tmp/disable_glsl.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"UseGLSL"="disabled"
_EOF_

./wine regedit /tmp/disable_glsl.reg
sleep 10s
}

enable_ddr_opengl() {
cat > /tmp/enable_ddr_opengl.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"DirectDrawRenderer"="opengl"
_EOF_

./wine regedit /tmp/enable_ddr_opengl.reg
sleep 10s
}

enable_multisampling() {
cat > /tmp/enable_multisampling.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\Software\Wine\Direct3D]
"Multisampling"="enabled"
_EOF_

./wine regedit /tmp/enable_multisampling.reg
sleep 10s
}

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
./wine regedit /tmp/virtualdesktop.reg
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

preptests() {
    ./server/wineserver -k || true
    rm -rf $WINEPREFIX winetricks || true
    sh winetricks gecko > /dev/null 2>&1 || exit 1
}

preptests_nogecko() {
    ./server/wineserver -k || true
    rm -rf $WINEPREFIX || true
    disable_gecko
}

# TODO: fix to use the SHA1SUM as well.
runtests() {
    echo "About to start $NAME-$MACHINE$TESTNAME test run. Expect no output for a while..." &&
    ./wine winetest-latest.exe -c -t $NAME-$MACHINE$TESTNAME 1>/dev/null 2>&1 &&
    rm -rf $WINEPREFIX
}

runtests64() {
    echo "About to start $NAME-$MACHINE$TESTNAME test run. Expect no output for a while..." &&
    ./wine winetest64-latest.exe -c -t $NAME-$MACHINE$TESTNAME 1>/dev/null 2>&1 &&
    rm -rf $WINEPREFIX
}

all_test() {
WINEDEBUG="+all"
TESTNAME="-all"
export WINEDEBUG
export TESTNAME
preptests
runtests
}

alsa_test() {
WINEDEBUG=""
TESTNAME="-alsa"
export WINEDEBUG
export TESTNAME
preptests
sh winetricks alsa
runtests
}

audioio_test() {
WINEDEBUG=""
TESTNAME="-audioio"
export WINEDEBUG
export TESTNAME
preptests
sh winetricks audioio
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
export WINEDEBUG
export TESTNAME
preptests
sh winetricks backbuffer
runtests
}

coreaudioio_test() {
WINEDEBUG=""
TESTNAME="-all"
export WINEDEBUG
export TESTNAME
preptests
sh winetricks coreaudioio
runtests
}

ddr_opengl_test() {
WINEDEBUG=""
TESTNAME="-ddr-opengl"
export WINEDEBUG
export TESTNAME
preptests
enable_ddr_opengl
runtests
}

esound_test() {
WINEDEBUG=""
TESTNAME="-esound"
export WINEDEBUG
export TESTNAME
preptests
sh winetricks esound
runtests
}

fbo_test() {
WINEDEBUG=""
TESTNAME="-fbo"
export WINEDEBUG
export TESTNAME
preptests
sh winetricks fbo
runtests
}

heap_test() {
WINEDEBUG="warn+heap"
TESTNAME="-heap"
export WINEDEBUG
export TESTNAME
preptests
runtests
}

jack_test() {
WINEDEBUG=""
TESTNAME="-jack"
export WINEDEBUG
export TESTNAME
preptests
sh winetricks jack
runtests
}

message_test() {
WINEDEBUG="+message"
TESTNAME="-message"
export WINEDEBUG
export TESTNAME
preptests
runtests
}

multisampling_test() {
WINEDEBUG=""
TESTNAME="-mltsmp"
export WINEDEBUG
export TESTNAME
preptests
enable_multisampling
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
export WINEDEBUG
export TESTNAME
preptests
disable_glsl
runtests
}

nowin16_test() {
WINEDEBUG=""
TESTNAME="-nowin16"
export WINEDEBUG
export TESTNAME
build_nowin16
preptests
runtests
}

oss_test() {
WINEDEBUG=""
TESTNAME="-oss"
export WINEDEBUG
export TESTNAME
preptests
sh winetricks oss
runtests
}

pbuffer_test() {
WINEDEBUG=""
TESTNAME="-pbuffer"
export WINEDEBUG
export TESTNAME
preptests
sh winetricks pbuffer
runtests
}

regular_test() {
WINEDEBUG=""
TESTNAME=""
export WINEDEBUG
export TESTNAME
preptests
runtests
}

relay_test() {
WINEDEBUG="+relay"
TESTNAME="-relay"
export WINEDEBUG
export TESTNAME
preptests
runtests
}

seh_test() {
WINEDEBUG="+seh"
TESTNAME="-seh"
export WINEDEBUG
export TESTNAME
preptests
runtests
}

virtual_desktop_test() {
WINEDEBUG=""
TESTNAME="-virtdesktop"
export WINEDEBUG
export TESTNAME
preptests
enable_virtual_desktop
runtests
}

werror_test() {
WINEDEBUG=""
TESTNAME="-werror"
export WINEDEBUG
export TESTNAME
build_werror
preptests
runtests
}

win64_test() {
WINEDEBUG=""
TESTNAME="-x64-nogecko"
export WINEDEBUG
export TESTNAME
build_win64
preptests_nogecko
runtests64
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
echo "--no-build - Disables (re)building Wine"
echo "--no-tests - Disables downloading/running winetest.exe"
echo "--no-regular - Skip running winetest.exe without special options"
echo "--alldebug - Runs winetest.exe with WINEDEBUG=+all"
echo "--backbuffer - Runs winetest.exe with offscreen rendering mode set to backbuffer"
echo "--fbo - Runs winetest.exe with offscreen rendering mode set to FBO"
echo "--heap - Runs winetest.exe with WINEDEBUG=+heap"
echo "--message - Runs winetest.exe with WINEDEBUG=+message"
echo "--no-gecko - Runs winetest.exe without gecko installed"
echo "--no-glsl - Runs winetest.exe with glsl disabled"
echo "--no-win16 - Builds Wine without win16 support and runs winetest.exe"
echo "--pbuffer - Runs winetest.exe with offscreen rendering mode set to pbuffer"
echo "--seh - Runs winetest.exe with WINEDEBUG=+seh"
echo "--virtual-desktop - Runs winetest.exe in a virtual desktop"
echo "--werror - Builds Wine with -Werror and runs winetest.exe"
echo "--win64 - Builds 64-bit Wine and runs winetest64.exe"
echo "You probably don't need any of the special options, though"
echo "The exception is --no-newtree/--no-build in case you want to run tests again without rebuilding Wine."
}

# There's probably a cleaner way to do this, but I'm lazy and I'll do it how I know
# Setting the variables here, to avoid errors below.
NEWTREE=0
NOBUILD=0
NODOWNLOAD=0
NOTESTS=0
NOREGULAR_TEST=0
ALLDEBUG_TEST=0
BACKBUFFER_TEST=0
DDR_OPENGL_TEST=0
FBO_TEST=0
HEAP_TEST=0
MESSAGE_TEST=0
MULTISAMPLING_TEST=0
NOGECKO_TEST=0
NOGLSL_TEST=0
NOWIN16_TEST=0
PBUFFER_TEST=0
SEH_TEST=0
VD_TEST=0
WERROR_TEST=0
WIN64_TEST=0

while test "$1" != ""
do
    case $1 in
    -v) set -x;;
    --no-newtree) export NEWTREE=1;;
    --no-build) export NOBUILD=1;;
    --no-download) export NODOWNLOAD=1;;
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
    --no-gecko) export NOGECKO_TEST=1;;
    --no-glsl) export NOGLSL_TEST=1;;
    --no-win16) export NOWIN16_TEST=1;;
    --oss) export OSS_TEST=1;;
    --pbuffer) export PBUFFER_TEST=1;;
    --seh) export SEH_TEST=1;;
    --virtual-desktop) export VD_TEST=1;;
    --werror) export WERROR_TEST=1;;
    --win-64) export WIN64_TEST=1;;
    *) echo Unknown arg $1; usage; exit 1;;
    esac
    shift
done

# Get new tree, if it wasn't disabled.
if [ $NEWTREE = 1 ]
    then 
        echo "not updating git tree"
else
    newtree
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

# Build Wine
if [ $NOBUILD != 1 ]
    then
        build_regular
fi

# Exit early, if tests aren't to be run:
if [ $NOTESTS = 1 ]
    then
        echo "tests aren't running, exiting"; exit
fi

# Get winetricks, used in below tests:
$GET "http://winezeug.googlecode.com/svn/trunk/winetricks" &&

if [ $NODOWNLOAD = 1 ]
    then
        echo "not downloading tests...I assume you have a good reason?"
else
    get_tests_32
fi

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

if [ $SEH_TEST = 1 ]
    then
        seh_test
fi

if [ $VD_TEST = 1 ]
    then
        virtual_desktop_test
fi

# Cleanup
rm -rf /tmp/*.reg $WINEPREFIX winetricks

exit
