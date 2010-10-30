#!/bin/sh
# Script to automate building Wine dll's and programs for Win32 using MinGW
#
# This assumes your wine-git tree is in $HOME/wine-git. If not, override it with WINEGIT=/path/to/your/wine/tree
#
# Copyright 2010 Austin English
# LGPL 2.1 License

set -eux

WINEGIT=${WINEGIT:-$HOME/wine-git}

cd "$WINEGIT"

# Files are placed in a directory named after the version
wineversion="`git describe`"
mkdir -p $wineversion/dlls $wineversion/programs

rm -rf build-native/ build-mingw/ wine-cross-temp/

mkdir build-mingw build-native

git clone -l . wine-cross-temp

cd build-native
../wine-cross-temp/configure
make __tooldeps__

cd ../build-mingw
# unset CC, if the user has it set, otherwise, breaks the build
unset CC
../wine-cross-temp/configure --host=i586-mingw32msvc --with-wine-tools=../build-native --without-freetype --without-x --disable-tests
make

# gather files for the user, then tar it up
find . -type f -name "*.dll" -exec mv {} ../$wineversion/dlls \;
# need to mrmove the test exe's here...
find . -type f -name "*.exe" -exec mv {} ../$wineversion/programs \;

cd ..

cat > "$wineversion/README" <<__EOF__
These are the Wine dll's and programs compiled for Win32.
They are meant to be used for testing, and should not be used arbitrarily.
Misuse can break your Windows system! WineHQ and the builder cannot be held liable for any damages.
__EOF__

tar -vjcf $wineversion-win32.tar.bz2 $wineversion

# cleanup
rm -rf $wineversion build-mingw build-native wine-cross-temp

# upload to SF
scp $wineversion-win32.tar.bz2 austin987,wine@frs.sourceforge.net:"/home/pfs/project/w/wi/wine/Win32\ Packages"
