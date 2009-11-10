#!/bin/sh
# Script to build valgrind for use with wine

VALGRIND_SVN_REV=10880
VEX_SVN_REV=1914
DIRNAME=valgrind-${VALGRIND_SVN_REV}
THISDIR=$(dirname "${0}")
THISDIR=$(cd "${THISDIR}" && /bin/pwd)

set -x
set -e

test -d "$DIRNAME" || svn co -r "${VALGRIND_SVN_REV}" "svn://svn.valgrind.org/valgrind/trunk" "$DIRNAME"

cd "$DIRNAME"

if ! test -f configure
then
  # Make sure svn gets the right version of the external VEX repo, too
  svn update -r "${VEX_SVN_REV}" VEX/

  # Add feature bug https://bugs.kde.org/show_bug.cgi?id=201170
  # "Want --show-possible option so I can ignore less likely leaks.
  patch -p0 < "${THISDIR}/possible.patch"

  # Fix/work around https://bugs.kde.org/show_bug.cgi?id=205541
  # which prevented valgrind from handling wine
  patch -p0 < "${THISDIR}/vbug205541.patch"

  sh autogen.sh
fi

OVERRIDE_LD_DIR="${THISDIR}/override_ld"
if ld --version | grep gold
then
  # If original ld is still around, try using that
  if test -x /usr/bin/ld.orig
  then
    echo "Using /usr/bin/ld.orig instead of gold to link valgrind"
    test -d "${OVERRIDE_LD_DIR}" && rm -rf "${OVERRIDE_LD_DIR}"
    mkdir "${OVERRIDE_LD_DIR}"
    ln -s /usr/bin/ld.orig "${OVERRIDE_LD_DIR}/ld"
    PATH="${OVERRIDE_LD_DIR}:${PATH}"
  # Ubuntu diverts original ld to ld.single when it installs binutils-gold
  elif test -x /usr/bin/ld.single
  then
    echo "Using /usr/bin/ld.single instead of gold to link valgrind"
    test -d "${OVERRIDE_LD_DIR}" && rm -rf "${OVERRIDE_LD_DIR}"
    mkdir "${OVERRIDE_LD_DIR}"
    ln -s /usr/bin/ld.single "${OVERRIDE_LD_DIR}/ld"
    PATH="${OVERRIDE_LD_DIR}:${PATH}"
  else
    echo "Cannot build valgrind with gold.  Please switch to normal /usr/bin/ld, rerun this script, then switch back to gold."
    exit 1
  fi
fi

# Desired parent directory for valgrind's bin, include, etc.
PREFIX="/usr/local/$DIRNAME"

./configure --prefix="${PREFIX}"
make -j4

if ./vg-in-place true
then
echo built valgrind passes smoke test, good
else
echo built valgrind fails smoke test
exit 1
fi

sudo make install
