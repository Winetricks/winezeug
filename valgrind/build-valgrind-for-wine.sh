#!/bin/sh
# Script to build valgrind for use with wine

VALGRIND_SVN_REV=10880
VEX_SVN_REV=1914
DIRNAME=valgrind-${VALGRIND_SVN_REV}
THISDIR=$(dirname "${0}")
THISDIR=$(cd "${THISDIR}" && /bin/pwd)

set -x
set -e

svn co -r "${VALGRIND_SVN_REV}" "svn://svn.valgrind.org/valgrind/trunk" "$DIRNAME"

cd "$DIRNAME"

# Make sure svn gets the right version of the external VEX repo, too
svn update -r "${VEX_SVN_REV}" VEX/

# Add feature bug https://bugs.kde.org/show_bug.cgi?id=201170
# "Want --show-possible option so I can ignore less likely leaks.
patch -p0 < "${THISDIR}/possible.patch"

# Fix/work around https://bugs.kde.org/show_bug.cgi?id=205541
# which prevented valgrind from handling wine
patch -p0 < "${THISDIR}/vbug205541.patch"

sh autogen.sh

OVERRIDE_LD_DIR="${THISDIR}/override_ld"
if ld --version | grep gold
then
echo "Cannot build valgrind with gold.  Please switch to normal /usr/bin/ld and rerun this script."
exit 1
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
