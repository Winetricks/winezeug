#!/bin/sh
# Script to set up build envrionment for chromium with visual c++
# and then build part or all of chromium.
# Without arguments, just sets up the build environment.
# With an argument, also starts the ide or builds the module indicated by the argument.
# Usage: build.sh ide|base|net|unit|clean
#
# Before running, patch wine to work around following problems (each has an attached patch):
#
# %~dp0 doesn't work properly
# bug http://bugs.winehq.org/show_bug.cgi?id=21382
# PATH screwed up
# bug http://bugs.winehq.org/show_bug.cgi?id=21322 

do_init=0
if test "$1"x = "--init"x
then
  do_init=1
fi

set -x
set -e

case "$OS" in
 "Windows_NT") 
   # Windows or Wine
   DRIVE_C=/cygdrive/c
   PROGRAM_FILES_x86="$DRIVE_C/Program Files (x86)"
   PROGRAM_FILES="$DRIVE_C/Program Files"
   WINE="cmd /c"
   ;;
 *)
   # Linux
   DIR=`pwd`
   export WINE=$HOME/wine-git/wine
   WINEPREFIX=${WINEPREFIX:-$HOME/.wine-chromium-tests}
   export WINEPREFIX
   DRIVE_C=$WINEPREFIX/drive_c
   PROGRAM_FILES_x86="$DRIVE_C/Program Files (x86)"
   PROGRAM_FILES="$DRIVE_C/Program Files"

   echo Using wine=$WINE, with WINEPREFIX=$WINEPREFIX
   if test $do_init = 1
   then
      rm -rf $WINEPREFIX
   fi
   ;;
esac

PROGRAM_FILES_x86_WIN="C:\\Program Files (x86)"
PROGRAM_FILES_WIN="C:\\Program Files"
if ! test -d "$PROGRAM_FILES_x86"
then
   PROGRAM_FILES_x86="$PROGRAM_FILES"
   PROGRAM_FILES_x86_WIN="$PROGRAM_FILES_WIN"
fi

while ! test -f "$DRIVE_C/cygwin/bin/unzip.exe"
do
   echo "Please install unzip and wget in cygwin"
   time sh ../../winetricks cygwin
done

# http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
# says "install Visual C++ 2005"
if test ! -f "$PROGRAM_FILES_x86/Microsoft Visual Studio 8/VC/vcvarsall.bat"
then
   time sh ../../winetricks vcrun2005
   time sh ../../winetricks vc2005trial
fi

# http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
# says to install a bunch of service packs and hotfixes, but they don't install in wine yet

# http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
# says "install Windows 7 SDK"
if test ! -f "$PROGRAM_FILES/Microsoft SDKs/Windows/v7.0/Lib/windowscodecs.lib"

then
   echo "Be sure to only select the minimum options needed for C development in the Platform SDK!"
   sh ../../winetricks -v psdkwin7
fi

# http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
# says "integrate windows SDK into Visual C++ 2005 by running windowssdkver -version:v7 -legacy",
# but that fails because of http://bugs.winehq.org/show_bug.cgi?id=21362
# So instead, I did it once by hand per
# http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Manually-registering-the-Platform-S
# then simply copied the resulting
# C:\Program Files\Microsoft Visual Studio 8\VC\vcpackages\VCProjectEngine.dll.config
# thereafter.
# 
# NOTE: on Vista, this copy doesn't seem to work; the file lands in a virtual
# overlay directory which is ignored by visual studio.  You have to
# copy the file using Explorer to override the virtual overlay.

cp VCProjectEngine.dll.config "$PROGRAM_FILES_x86/Microsoft Visual Studio 8/VC/vcpackages/"

mkdir -p "$DRIVE_C/chromium"
cp depot_tools.reg depot_tools.patch "$DRIVE_C/chromium"
cd "$DRIVE_C/chromium"

# http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
# says "get depot_tools per http://dev.chromium.org/developers/how-tos/install-gclient" 
if test ! -f "$DRIVE_C/chromium/depot_tools/gclient"
then
   mkdir depot_tools
   svn co http://src.chromium.org/svn/trunk/tools/depot_tools
   # Add it to user's PATH.  Note: native regedit requires absolute path.
   $WINE regedit C:\\chromium\\depot_tools.reg
fi

# Get gclient to install svn
if test ! -d depot_tools/svn_bin
then
   # Work around http://bugs.winehq.org/show_bug.cgi?id=19799 and http://bugs.winehq.org/show_bug.cgi?id=21381
   if test "$OS" != Windows_NT
   then
      patch -p0 < depot_tools.patch
   fi
   # First run causes it to download and install svn.
   $WINE cmd /c depot_tools\\gclient.bat || true
   if test "$OS" != Windows_NT
   then
      # It fails at the very last moment, so do the missing two steps.
      cp depot_tools/bootstrap/win/python.new.bat depot_tools/python.bat
      cp depot_tools/bootstrap/win/python.new depot_tools/python
   fi
fi

if test "$OS" != Windows_NT
then
   # gyp needs to know username and domain for some reason (see http://code.google.com/p/gyp/issues/detail?id=100 )
   export USERNAME=dank
   export USERDOMAIN=kegel.com
fi
# Work around Bug 19533 - reg.exe missing most options; breaks firefox and chromium builds
# http://bugs.winehq.org/show_bug.cgi?id=19533
export GYP_GENERATORS=msvs
export GYP_MSVS_VERSION=2005

# Get sources!
if test ! -d src
then
   rm -f .gclient .gclient_entries
   $WINE cmd /c gclient config http://src.chromium.org/svn/trunk/src 
   $WINE cmd /c gclient sync

   # Follow instructions in third_party/cygwin/README.google for
   # setting up mounts for the bundled version of cygwin.
   # Not sure why we have to do this on wine but not windows,
   # but not doing it makes the libcmt custom build step fail
   # because #!/bin/sh doesn't point to the embedded cygwin's sh
   # (though #!/cygdrive/c/cygwin/bin/sh does, showing it's just a 
   # mount problem).
   $WINE cmd /c src\\third_party\\cygwin\\setup_mount.bat
fi

cd src

buildproj() {
   rm -f $1.log
   $WINE "$IDEDIR\\devenv" /build Debug /out $1.log /project $1 chrome\\chrome.sln
}

# Now that the environment is set up, get on with whatever the developer needs to do.

IDEDIR="$PROGRAM_FILES_x86_WIN\\Microsoft Visual Studio 8\\Common7\\IDE" 
case "$1" in
clean)    rm -rf "$DRIVE_C/chromium/src/chrome/Debug" ;;
kill)     ~/wine-git/server/wineserver -k;;
runhooks) $WINE cmd /c gclient runhooks --force ;;
start)    $WINE "$IDEDIR\\mspdbsrv" -start -spawn -shutdowntime -1 ;;
ide)      $WINE "$IDEDIR\\devenv" chrome\\chrome.sln ;;
base)     buildproj base_unittests;;
net)      buildproj net_unittests;;
unit)     buildproj unit_tests;;
*) echo "Usage: build.sh ide|base|net|unit|clean|kill|start" ;;
esac
