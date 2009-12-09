#!/bin/sh
# chromium-savetests.sh
# Run from parent of chromium's src directory.
# Cygwin sh script to save a respectable subset of chromium's test suite
# from a windows build.
#
# To run the saved tests, grab a copy of the winezeug repository,
# cd into winezeug/testsuites/chromium,
# unpack this tarball there, and run chromium-runtests.sh.

set -x

# Parse arguments

TARGET=Debug

while test "$1" != ""
do
  case $1 in
  --target) TARGET=$2; shift;;
  *) echo bad arg $1; exit 1;;
  esac
  shift
done

# Record which version of the source this was built with
cd src
svn info > svninfo.txt
cd ..

# wow_helper needed by sbox_validation_tests
# chrome needed by ui_tests (and lots others)

FILES="
 src/svninfo.txt \
 src/app/test/data \
 src/base/data \
 src/chrome/$TARGET/icudt42.dll \
 src/chrome/$TARGET/crash_service.exe \
 src/chrome/$TARGET/pthreads.dll \
 src/chrome/$TARGET/wow_helper.exe \
 src/chrome/$TARGET/locales/en-US.dll \
 src/chrome/$TARGET/themes/default.dll \
 src/chrome/$TARGET/test_chrome_plugin.dll \
 src/chrome/test/data \
 src/chrome/test/unit \
 src/courgette/testdata \
 src/ipc/data \
 src/media/test/data \
 src/net/data \
 src/net/tools \
 src/third_party/{pyftpdlib,python_24,tlslite,hunspell/dictionaries/en-US*.bdic} \
"

# Skip chrome itself for the moment, it makes the download huge.
# src/chrome/$TARGET/chrome.{dll,exe} \
# src/chrome/$TARGET/chrome_dll.pdb \
# src/chrome/$TARGET/chrome_exe.pdb \

# Tests, grouped by how long they take to run
# Skip ones that require chrome itself for the moment
TESTS_1="googleurl_unittests printing_unittests sbox_validation_tests setup_unittests"
#TESTS_10="app_unittests courgette_unittests ipc_tests reliability_tests sbox_integration_tests sbox_unittests tab_switching_test tcmalloc_unittests url_fetch_test"
TESTS_10="app_unittests courgette_unittests ipc_tests sbox_unittests tcmalloc_unittests"
#TESTS_100="automated_ui_tests installer_util_unittests media_unittests nacl_ui_tests net_perftests net_unittests plugin_tests sync_unit_tests"
TESTS_100="media_unittests net_unittests"
#TESTS_1000="base_unittests interactive_ui_tests memory_test page_cycler_tests perf_tests test_shell_tests unit_tests"
TESTS_1000="base_unittests unit_tests"
#TESTS_10000="ui_tests startup_tests"

# Save the tests we're interested in
for test in $TESTS_1 $TESTS_10 $TESTS_100 $TESTS_1000
do
 FILES="$FILES src/chrome/$TARGET/$test.{exe,pdb} " 
done

FILES=`eval echo $FILES`

# Exclude these large subdirectories of src/chrome/test/data
cat > toobig.txt <<_EOF_
firefox2_nss_mac
firefox3_nss_mac
layout_tests
profiles/*theme
profiles/*frame
safari_import
safe_browsing
sunspider
v8_benchmark
_EOF_

tar -cjvf chromium-tests.tar.bz2 \
 --exclude=.svn --exclude="*.user" --exclude="*.pyc" --exclude-from toobig.txt \
 $FILES


