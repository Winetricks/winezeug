#!/bin/sh
# First step in building chromium with visual c++
# Before running, patch wine to work around following problems:
#
# %~dp0 doesn't work properly
# bug http://bugs.winehq.org/show_bug.cgi?id=21382 patch http://bugs.winehq.org/attachment.cgi?id=25746

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
   ;;
 *)
   # Linux
   DIR=`pwd`
   export WINE=$HOME/wine-git/wine
   WINEPREFIX=${WINEPREFIX:-$HOME/.wine-chromium-tests}
   export WINEPREFIX
   DRIVE_C=$WINEPREFIX/drive_c
   echo Using wine=$WINE, with WINEPREFIX=$WINEPREFIX
   if test $do_init = 1
   then
      rm -rf $WINEPREFIX
   fi
esac

while ! test -f "$DRIVE_C/cygwin/bin/unzip.exe"
do
   echo "Please install unzip and wget in cygwin"
   time sh ../../winetricks cygwin
done

# http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
# says "install Visual C++ 2005"
if test ! -f "$DRIVE_C/Program Files/Microsoft Visual Studio 8/VC/vcvarsall.bat"
then
   time sh ../../winetricks vcrun2005
   time sh ../../winetricks vc2005trial
fi

# http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
# says to install a bunch of service packs and hotfixes, but they don't install in wine yet

# http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
# says "install Windows 7 SDK"
if test ! -f "$DRIVE_C/Program Files/Microsoft SDKs/Windows/v7.0/Lib/windowscodecs.lib"
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

cp VCProjectEngine.dll.config "$DRIVE_C/Program Files/Microsoft Visual Studio 8/VC/vcpackages/"

mkdir -p "$DRIVE_C/chromium"
cp depot_tools.reg depot_tools.patch "$DRIVE_C/chromium"
cd "$DRIVE_C/chromium"

# http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
# says "get depot_tools per http://dev.chromium.org/developers/how-tos/install-gclient" 
if test ! -f "$DRIVE_C/chromium/depot_tools/gclient"
then
   mkdir depot_tools
   svn co http://src.chromium.org/svn/trunk/tools/depot_tools
   # Add it to user's PATH
   $WINE regedit depot_tools.reg
fi

# Get gclient to install svn
if test ! -d depot_tools/svn_bin
then
   # Work around http://bugs.winehq.org/show_bug.cgi?id=19799 and http://bugs.winehq.org/show_bug.cgi?id=21381
   patch -p0 < depot_tools.patch
   # First run causes it to download and install svn.
   $WINE cmd /c gclient help || true
   # It fails at the very last moment, so do the missing two steps.
   cp depot_tools/bootstrap/win/python.new.bat depot_tools/python.bat
   cp depot_tools/bootstrap/win/python.new depot_tools/python
   # Show that it works.
   $WINE cmd /c gclient help 
fi

# Get sources!
if test ! -d src
then
   gclient config http://src.chromium.org/svn/trunk/src 
   gclient sync
fi

# Build!
$WINE "C:\Program Files\Microsoft Visual Studio 8\Common7\IDE\devenv"

echo done
