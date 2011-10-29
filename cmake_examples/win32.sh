#!/bin/sh
# Script to install Windows prerequisites for the examples
# Can be run in cygwin or in linux
# 
set -x

WINE="${WINE:-wine}"
export WINE

run() {
    case "$OS" in
    "Windows_NT") cmd /c $* ;;
    *) $WINE $* ;;
    esac
}

# FIXME: move cmake and boost into winetricks
test -f cmake-2.8.6-win32-x86.exe || wget http://www.cmake.org/files/v2.8/cmake-2.8.6-win32-x86.exe
run cmake-2.8.6-win32-x86.exe /S

test -f boost_1_47_setup.exe || wget http://boostpro.com/download/boost_1_47_setup.exe
run boost_1_47_setup.exe 

test -f winetricks || wget http://winetricks.googlecode.com/svn/trunk/src/winetricks
# Do as silent an install as winetricks knows how to do
# In the Platform SDK dialog, choose just the windows headers, libraries, and compiler
sh winetricks --no-isolate -q psdkwin7 

# Some examples might require Visual C++ later
# sh winetricks vc2005express
