#!/bin/sh
# Simple script to download and build firefox for windows
# Steps to use on Windows:
# 1. install cygwin and its versions of mercurial and wget.
# 2. run http://kegel.com/wine/vc2005x.sh
# to install Visual Studio 2005 Express and the Platform SDK 2003.
# 3. run this script in Cygwin.
# Steps to use on Linux:
# 1. run winetricks cygwin, and install cygwin's mercurial and wget.
# 2. run winetricks msxml6 dotnet20 vcrun2005 vc2005express psdk2003
# 3. cd ~/.wine/drive_c/cygwin; wine cmd /c cygwin.bat
# 4. in that cygwin shell, run this script.
#
# Based on 
# https://developer.mozilla.org/en/Build_Documentation
# https://developer.mozilla.org/En/Simple_Firefox_build
# https://developer.mozilla.org/en/Windows_Build_Prerequisites
# https://developer.mozilla.org/en/atlbase.h
#
# 18-22 Aug 2009  Dan Kegel

set -x
set -e

if [ ! -d c:/mozilla-build ]
then
  test -f MozillaBuildSetup-1.4.exe || wget http://ftp.mozilla.org/pub/mozilla.org/mozilla/libraries/win32/MozillaBuildSetup-1.4.exe
  chmod +x MozillaBuildSetup-1.4.exe
  # No silent install?  See
  # https://wiki.mozilla.org/ReleaseEngineering:OPSI
  # for auto-it script?
  cmd /c MozillaBuildSetup-1.4.exe /S
fi

test -d firefox-191src || hg clone http://hg.mozilla.org/releases/mozilla-1.9.1/ firefox-191src

cd firefox-191src

# No longer needed as of Sept 12 or so, yay
# patch away the tests for mt.exe (http://bugs.winehq.org/show_bug.cgi?id=19780)
#if test ! -f bug19780-kludge.patch
#then
#  wget http://kegel.com/wine/bug19780-kludge.patch
#  patch -p1 < bug19780-kludge.patch
#fi

if test ! -f .mozconfig
then
  # Normal debug config
  # But only depend on old SDK features, as we can't yet install vista sdk on wine (http://bugs.winehq.org/show_bug.cgi?id=19636)
  # And don't enable debugging, since -Zi broken (http://bugs.winehq.org/show_bug.cgi?id=19781)
  # (although perhaps /Z7 would work.)
  # If you disable debugging, you must enable optimization (https://bugzilla.mozilla.org/show_bug.cgi?id=338224)
  # Disable things that need ATL, since the old SDK doesn't have it
  cat > .mozconfig <<_EOF_
ac_add_options --enable-application=browser
mk_add_options MOZ_CO_PROJECT=browser
mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/ff-dbg
ac_add_options --enable-optimize
ac_add_options --disable-debug 
ac_add_options --disable-tests
ac_add_options --with-windows-version=501
ac_add_options --disable-vista-sdk-requirements
ac_add_options --disable-xpconnect-idispatch
ac_add_options --disable-activex
ac_add_options --disable-activex-scripting
ac_add_options --disable-accessibility
_EOF_
fi

# Use a hacked start-msvc8.bat to work around
# http://bugs.winehq.org/show_bug.cgi?id=19778
# http://bugs.winehq.org/show_bug.cgi?id=15359
# and other bugs in wine's cmd
# and also point to the include and lib directories of
# the 2003 sdk, which start-msvc8.bat might not do right.
# This is copied by wine-part3.sh now.
#cd c:/mozilla-build
#wget http://kegel.com/wine/start-msvc8-wine.bat

set +x
echo "If using wine, exit this cmd, then run"
echo "  sh wine-part3.sh"
echo ""
echo "If using Windows:"
echo "  cd c:\\mozilla-build"
echo "  start-msvc8.bat"
echo "  Then do "
echo "    cd /c/firefox-191src; make -f client.mk"
echo "  in the bash that start-msvc8.bat started."
