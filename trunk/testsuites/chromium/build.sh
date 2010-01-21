#!/bin/sh
# Script to set up build envrionment for chromium with visual c++
# and then build part or all of chromium.
# Without arguments, just sets up the build environment.
# With an argument, also starts the ide or builds the module indicated by the argument.
#
# If running on Linux:
# First patch wine for the following problems (each has an attached patch):
#  %~dp0 doesn't work properly
#    http://bugs.winehq.org/show_bug.cgi?id=21382
#  PATH screwed up
#    http://bugs.winehq.org/show_bug.cgi?id=21322 
# and do
#  sudo apt-get install cabextract winbind
# or winetricks and svn will complain.
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

usage() {
   set +x
   echo "Usage: build.sh [--init] build|clean|cmd|gclient|ide|kill|start"
   echo " --init: wipe out wine bottle and start over"
   echo " build XXX: build project XXX (e.g. base_unittests, net_unittests, unit_tests)"
   echo " clean: remove built objects and binaries in src/chrome/Debug"
   echo " cmd: windows command prompt"
   echo " gclient: run gclient with given arguments"
   echo " ide: run Visual C++ IDE"
   echo " kill: kill wineserver"
   echo " start: start persistent pdbserver (else you'll see random hangs)"
   exit 1
}

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
   time sh ../../winetricks cygwin
done

# http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
# says "install Visual C++ 2005"
if test ! -f "$PROGRAM_FILES_x86/Microsoft Visual Studio 8/VC/vcvarsall.bat"
then
   time sh ../../winetricks -q vcrun2005
   time sh ../../winetricks vc2005trial
   # The following two fail in Wine; use vcsave/vcload verbs for now.
   time sh ../../winetricks vc2005sp1
   time sh ../../winetricks vc2005hotfix
fi

# http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
# says to install a bunch of service packs and hotfixes, but they don't install in wine yet

# http://dev.chromium.org/developers/how-tos/build-instructions-windows#TOC-Prerequisite-software
# says "install Windows 7 SDK"
if test ! -f "$PROGRAM_FILES/Microsoft SDKs/Windows/v7.0/Lib/windowscodecs.lib"

then
   echo "Be sure to only select the minimum options needed for C development in the Platform SDK!"
   sh ../../winetricks -v psdkwin7

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
   
   case "$OS" in
   Windows_NT) echo "Please copy VCProjectEngine.dll.config to $PROGRAM_FILES_x86/Microsoft Visual Studio 8/VC/vcpackages/" ;;
   *) cp VCProjectEngine.dll.config "$PROGRAM_FILES_x86/Microsoft Visual Studio 8/VC/vcpackages/" ;;
   esac
   
fi

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

# Get gclient to install svn and python
if test ! -d depot_tools/python_bin
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

# Set up svn client and cygwin
if test ! -d src
then
   rm -f .gclient .gclient_entries
   $WINE cmd /c depot_tools\\gclient.bat config http://src.chromium.org/svn/trunk/src 
   # FIXME: make this optional somehow.
   $WINE cmd /c depot_tools\\gclient.bat sync

   # Follow instructions in third_party/cygwin/README.google for
   # setting up mounts for the bundled version of cygwin.
   # Not sure why we have to do this on wine but not windows,
   # but not doing it makes the libcmt custom build step fail
   # because #!/bin/sh doesn't point to the embedded cygwin's sh
   # (though #!/cygdrive/c/cygwin/bin/sh does, showing it's just a 
   # mount problem).
   $WINE cmd /c src\\third_party\\cygwin\\setup_mount.bat

   # For my convenience while developing this script, maybe useful for others
   ln -s "$DRIVE_C/chromium/src" "$OLDDIR"
fi

cd src

do_build() {
   case $1 in
   base_unittests|net_unittests|unit_tests) ;;
   *) echo unknown project $1, might explode;;
   esac

   rm -f $1.log
   time $WINE "$IDEDIR\\devenv" /build Debug /out $1.log /project $1 chrome\\chrome.sln
}

do_clean() {
   rm -rf "$DRIVE_C/chromium/src/chrome/Debug" 
}

do_gclient() {
   $WINE cmd /c "c:\\chromium\\depot_tools\\gclient.bat" "$@"
}

do_kill() {
   $WINESERVER -k || true
}

do_start() {
   $WINE "$IDEDIR\\mspdbsrv" -start -spawn -shutdowntime -1 > start.log 2>&1 &
}

# Example of how to do it all from start to finish
do_all() {
  do_kill
  do_start
  do_clean
  do_gclient sync
  do_build base_unittests
  do_kill
}

# Now that the environment is set up, get on with whatever the developer needs to do.

IDEDIR="$PROGRAM_FILES_x86_WIN\\Microsoft Visual Studio 8\\Common7\\IDE" 
case "$1" in
all)      do_all ;;
build)    shift; do_build $1;;
clean)    do_clean ;;
cmd)      $WINE cmd ;;
gclient)  shift; do_gclient "$@" ;;
ide)      $WINE "$IDEDIR\\devenv" chrome\\chrome.sln ;;
kill)     do_kill;;
vcsave)   # fixme: abort if $IDEDIR/devenv.exe does not exist
          tar -C "$PROGRAM_FILES_x86" -czvf vc8.tgz "Microsoft Visual Studio 8";;
vcload)   tar -C "$PROGRAM_FILES_x86" -xzvf vc8.tgz ;;
start)    do_start ;;
*)        usage ;;
esac
