#!/bin/sh
# First step in building firefox in wine with visual c++

set -x

DIR=`pwd`
export WINE=$HOME/wine-git/wine
export WINEPREFIX=$DIR/.wine
echo Using wine=$WINE, with WINEPREFIX=$WINEPREFIX

if false
then
  rm -rf $WINEPREFIX
  echo "Please install mercurial and wget in cygwin"
  sh ../../winetricks cygwin
  sh ../../winetricks vcrun2005
  sh ../../winetricks vc2005express
  sh ../../winetricks psdk2003
fi

cp firefox-download-and-build.sh $WINEPREFIX/drive_c/cygwin

echo "Second step: run the windows side of build by doing 'sh firefox-download-and-build.sh' in cygwin's shell"
$WINE cmd /c c:\\cygwin\\cygwin.bat
