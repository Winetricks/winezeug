#!/bin/sh
# Third step in building firefox in wine with visual c++
set -x

DIR=`pwd`
export WINE=$HOME/wine-git/wine
export WINEPREFIX=$DIR/.wine
echo Using wine=$WINE, with WINEPREFIX=$WINEPREFIX

cp start-msvc8-wine.bat $WINEPREFIX/drive_c/mozilla-build
cd $WINEPREFIX/drive_c/mozilla-build

set +x

echo "Now do"
echo "  cd /c/cygwin/firefox-191src"
echo "  make -f client.mk"
echo "in the coming wineconsole to actually build firefox."

$WINE wineconsole cmd /c start-msvc8-wine.bat > winelog 2>&1
