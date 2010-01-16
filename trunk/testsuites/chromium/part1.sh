#!/bin/sh
# First step in building chromium in wine with visual c++

set -x
set -e

DIR=`pwd`
export WINE=$HOME/wine-git/wine
WINEPREFIX=${WINEPREFIX:-$HOME/.wine-chromium-tests}
export WINEPREFIX
echo Using wine=$WINE, with WINEPREFIX=$WINEPREFIX

if true
then
  rm -rf $WINEPREFIX
  echo "Please install unzip and wget in cygwin"
  sh ../../winetricks cygwin
  sh ../../winetricks vcrun2005
  sh ../../winetricks vc2005trial
  echo "Be sure to only select the minimum options needed for C development in the Platform SDK!"
  sh ../../winetricks psdkwin7
fi
