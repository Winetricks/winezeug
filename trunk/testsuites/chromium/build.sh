#!/bin/sh
# Script to set up build envrionment for chromium with visual c++
# and then build part or all of chromium.
# Simple usage:  sh build.sh all
#
# If running on Linux:
# First build the latest wine from svn, then do
#  sudo apt-get install cabextract winbind
# or winetricks and svn will complain.
#
# Note: devenv can use more than 1024 files, so to avoid build errors,
# raise ulimit -n to 5000 or so before running.  e.g. to get a single shell
# with a high ulimit -n, do
#  sudo bash
#    ulimit -n 10000
#    su YOURNAME
# Then run the build in that session.
#
# Also, you might want to turn on parallel building
# by creating the file ~/.wine-chromium-tests/drive_c/users/$YOURUSERNAME/.gyp/include.gypi
# containing the five lines
#   { 
#      'variables': { 
#          'msvs_multi_core_compile': 1 
#      } 
#   }
# See http://groups.google.com/group/chromium-dev/msg/0011dfa6dbf335bd
#
# If running on Windows:
# First download cygwin's setup.exe to new directory c:/cygpkgs
# and run it to install Cygwin, Subversion, cabextract, unzip, and wget.
# Note: until wine can run cygwin 1.7, be sure to use the same setup.exe 
# as winetricks does, i.e.
#   http://kegel.com/cygwin/1.5/setup.exe
# but use the -X commandline option,
# and paste in the same repo as cygwin tells you to, i.e.
#   ftp://www.fruitbat.org/pub/cygwin/circa/2009/09/08/111037
#
# Use Subversion to check out winezeug.googlecode.com, and run this script 
# from the Winezeug tree.
#
# Requires, oh, 32 gigabytes of free space.  Checks out about 5 GB of source code.

usage() {
   set +x
   echo "Usage: build.sh [--init] all|build|clean|cmd|gclient|ide|kill|run|source|sh|start|tools|vcinst|vcload|vcsave"
   echo " --init: wipe out wine bottle and start over"
   echo " all: everything from soup to nuts.  The other commands are for advanced users."
   echo " build XXX: build project XXX (e.g. base_unittests, net_unittests, unit_tests)"
   echo " clean: remove built objects and binaries in src/chrome/Debug"
   echo " cmd: windows command prompt"
   echo " gclient: run gclient with given arguments"
   echo " ide: run Visual C++ IDE"
   echo " kill: kill wineserver"
   echo " run: run the chrome.exe you built"
   echo " source: check out source code for first time"
   echo " sh: cygwin command prompt"
   echo " start: start persistent pdbserver (else you'll see random hangs)"
   echo " tools: install depot_tools"
   echo " vcinst: install Visual C++ 2005, sp1, hotfixes"
   echo " vcload: load a copy of Visual C++ saved by vcsave"
   echo " vcsave: save a copy of Visual C++ to the file vc8.tgz"
   exit 1
}

mode=Debug

do_init=0
if test "$1"x = "--init"x
then
  do_init=1
  shift
fi

set -e

OLDDIR=`pwd`

case "$OS" in
 "Windows_NT") 
   # Windows or Wine
   DRIVE_C=/cygdrive/c
   PROGRAM_FILES_x86="$DRIVE_C/Program Files (x86)"
   PROGRAM_FILES="$DRIVE_C/Program Files"
   WINE="cmd /c"
   WINESERVER=true
   ;;
 *)
   # Linux
   DIR=`pwd`
   WINESERVER=${WINESERVER:-$HOME/wine-git/server/wineserver}
   WINE=${WINE:-$HOME/wine-git/wine}
   export WINE
   WINEDEBUG=${WINEDEBUG:-fixme-all,warn-all,err-all}
   export WINEDEBUG
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

while ! test -f "$DRIVE_C/cygwin/bin/unzip.exe" || ! test -f "$DRIVE_C/cygwin/bin/wget.exe" 
do
   echo "Please install unzip and wget in cygwin"
   time sh "$OLDDIR"/../../winetricks cygwin
done

check_visualc() {
 # http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
 # says "install Visual C++ 2005"
 if test ! -f "$PROGRAM_FILES_x86/Microsoft Visual Studio 8/VC/vcvarsall.bat"
 then
   time sh "$OLDDIR"/../../winetricks -q vcrun2005
   time sh "$OLDDIR"/../../winetricks -q vc2005trial
   echo "Let Visual Studio start up, then quit.  This is needed to let it register itself."
   $WINE "$IDEDIR\\devenv"
   # http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
   # says to install a bunch of service packs and hotfixes, but they don't install in wine yet
   echo "In Wine, this will take fifteen minutes and then fail, so press ^C now, "
   echo "put the vc8.tgz you made on windows into src/, do 'sh build.sh vcload', then run again."
   time sh "$OLDDIR"/../../winetricks vc2005sp1
   time sh "$OLDDIR"/../../winetricks vc2005hotfix
 fi

 # http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
 # says "install Windows 7 SDK"
 if test ! -f "$PROGRAM_FILES/Microsoft SDKs/Windows/v7.0/Lib/windowscodecs.lib"
 then
   echo "Be sure to only select the minimum options needed for C development in the Platform SDK!"
   sh "$OLDDIR"/../../winetricks -q vcrun2008
   sh "$OLDDIR"/../../winetricks -v psdkwin7
 fi

 # http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
 # says "integrate windows SDK into Visual C++ 2005 by running windowssdkver -version:v7 -legacy",
 $WINE "$PROGRAM_FILES/Microsoft SDKs/Windows/v7.0/Setup/windowssdkver" -version:v7        
}

check_tools() {
 cd "$DRIVE_C/chromium"
 cp "$OLDDIR"/depot_tools.reg "$OLDDIR"/depot_tools.patch "$DRIVE_C/chromium"
 
 # http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
 # says "get depot_tools per http://dev.chromium.org/developers/how-tos/install-gclient" 
 if test ! -f "$DRIVE_C/chromium/depot_tools/gclient"
 then
   mkdir depot_tools
   svn co http://src.chromium.org/svn/trunk/tools/depot_tools
   # Add it to user's PATH.  Note: native regedit requires absolute path.
   $WINE regedit C:\\chromium\\depot_tools.reg
 fi

 # Get gclient to install svn and python
 if test ! -d depot_tools/python_bin
 then
   # Work around http://bugs.winehq.org/show_bug.cgi?id=19799 and http://bugs.winehq.org/show_bug.cgi?id=21381
   if test "$OS" != Windows_NT
   then
      patch -p0 < depot_tools.patch
   fi
   # First run causes it to download and install svn.
   rm -f svn*.zip
   echo "About to run depot_tools/gclient.bat"
   # $WINE cmd
   $WINE cmd /c depot_tools\\gclient.bat || true
   if test "$OS" != Windows_NT
   then
      if test ! -d depot_tools/python_bin
      then
         echo "Please do 'sudo apt-get install winbind', remove c:/chromium/depot_tools, and try again."
         exit 1
      fi
      # It fails at the very last moment, so do the missing two steps.
      cp depot_tools/bootstrap/win/python.new.bat depot_tools/python.bat
      cp depot_tools/bootstrap/win/python.new depot_tools/python
   fi
 fi
}

check_source() {
 cd "$DRIVE_C/chromium"
 # Set up svn client and cygwin
 if test ! -f .gclient
 then
   $WINE cmd /c depot_tools\\gclient.bat config http://src.chromium.org/svn/trunk/src 
   # FIXME: make this optional somehow.
   echo "Checking out roughly 4.8 gigabytes of source.  Please wait."
   $WINE cmd /c depot_tools\\gclient.bat sync

   # Follow instructions in third_party/cygwin/README.google for
   # setting up mounts for the bundled version of cygwin.
   # Not sure why we have to do this on wine but not windows,
   # but not doing it makes the libcmt custom build step fail
   # because #!/bin/sh doesn't point to the embedded cygwin's sh
   # (though #!/cygdrive/c/cygwin/bin/sh does, showing it's just a 
   # mount problem).
   $WINE cmd /c src\\third_party\\cygwin\\setup_mount.bat
 fi
}

do_build() {
   echo -n "File descriptor limit is  "
   ulimit -n
   echo "If that's below 5000, you might want to raise it."
   cd "$DRIVE_C/chromium/src"
   case $1 in
   base_unittests|net_unittests|unit_tests) ;;
   *) echo unknown project $1, might explode;;
   esac

   rm -f $1.log
   time $WINE "$IDEDIR\\devenv" /build $mode /out $1.log /project $1 chrome\\chrome.sln
}

do_clean() {
   cd "$DRIVE_C/chromium/src"
   rm -rf "$DRIVE_C/chromium/src/chrome/$mode" 
}

do_gclient() {
   cd "$DRIVE_C/chromium/src"
   $WINE cmd /c "c:\\chromium\\depot_tools\\gclient.bat" "$@"
}

do_kill() {
   $WINESERVER -k || true
}

do_start() {
   cd "$DRIVE_C/chromium/src"
   $WINE "$IDEDIR\\mspdbsrv" -start -spawn -shutdowntime -1 > start.log 2>&1 &
}

# Example of how to do it all from start to finish
do_all() {
  do_kill
  # tools must come before source
  check_tools
  check_source
  check_visualc
  # and if running on Linux, ^C when sp1 install hangs, do vcload, and run again.
  do_start
  do_clean
  #do_gclient sync
  #do_gclient runhooks --force
  do_build base
  do_kill
}

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

# Work around http://bugs.winehq.org/show_bug.cgi?id=21174
# and http://bugs.winehq.org/show_bug.cgi?id=21484
# (though we'll need a new workaround for 21484 once 21174 is fixed)
export NUMBER_OF_PROCESSORS_PLUS_1=1

mkdir -p "$DRIVE_C/chromium"
# For my convenience while developing this script, maybe useful for others
# though the symlink won't be much use until svn creates that directory
ln -sf "$DRIVE_C/chromium/src" "$OLDDIR"

sh "$OLDDIR"/../../winetricks nocrashdialog

IDEDIR="$PROGRAM_FILES_x86_WIN\\Microsoft Visual Studio 8\\Common7\\IDE" 
while test "$1" != ""
do
    cd "$DRIVE_C/chromium"
    case "$1" in
    all)      do_all ;;
    bench)    do_bench ;;
    build)    shift; do_build $1;;
    clean)    do_clean ;;
    run)      $WINE c:\\chromium\\src\\chrome\\$mode\\chrome.exe --no-sandbox ;;
    cmd)      $WINE cmd $*; exit;;
    sh)       $WINE cmd /c c:\\cygwin\\cygwin.bat ;;
    ash)      shift; $WINE c:\\cygwin\\bin\\ash.exe "$@";;
    gclient)  shift; do_gclient "$@" ;;
    bareide)  cd src; $WINE "$IDEDIR\\devenv" ;;
    ide)      cd src; $WINE "$IDEDIR\\devenv" chrome\\chrome.sln ;;
    kill)     do_kill;;
    release)  mode=Release;;
    source)   check_source;;
    tools)    check_tools;;
    vcinst)   check_visualc;;
    vcsave)   cd src; sh -x "$OLDDIR/../../winetricks" vc2005save ;;
    vcload)   cd src; sh -x "$OLDDIR/../../winetricks" vc2005load ;;
    start)    do_start ;;
    *)        usage ;;
    esac
    shift
done
