#!/bin/sh
# Script to install Windows prerequisites for the examples
# Can be run in cygwin or in linux
# 
set -x
set -e

WINE="${WINE:-wine}"
export WINE

run() {
    case "$OS" in
    "Windows_NT") chmod +x $1; cmd /c $* ;;
    *) $WINE $* ;;
    esac
}

# FIXME: move cmake and boost into winetricks
test -f cmake-2.8.6-win32-x86.exe || wget http://www.cmake.org/files/v2.8/cmake-2.8.6-win32-x86.exe
run cmake-2.8.6-win32-x86.exe /S

# Boost 1.47 is available, but cmake-2.8.6's findBoost doesn't support it yet
test -f boost_1_46_1_setup.exe || wget http://boostpro.com/download/boost_1_46_1_setup.exe
run boost_1_46_1_setup.exe 

test -f winetricks || wget http://winetricks.googlecode.com/svn/trunk/src/winetricks
# Do as silent an install as winetricks knows how to do
# In the Platform SDK dialog, choose just the windows headers, libraries, and compiler

# Install either psdkwin7 and vc2005express:
# sh winetricks --no-isolate -q psdkwin7 vc2005express
# Or vc2008express:
# http://www.microsoft.com/visualstudio/en-us/products/2008-editions/express
