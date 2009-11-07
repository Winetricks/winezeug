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

# Record which version of the source this was built with
cd src
svn info > svninfo.txt
cd ..

# wow_helper needed by sbox_validation_tests
# chrome needed by ui_tests (and lots others)

FILES="
 src/svninfo.txt \
 src/base/data \
 src/chrome/Debug/icudt42.dll \
 src/chrome/Debug/crash_service.exe \
 src/chrome/Debug/pthreads.dll \
 src/chrome/Debug/wow_helper.exe \
 src/chrome/Debug/locales/en-US.dll \
 src/chrome/Debug/themes/default.dll \
 src/chrome/test/data \
 src/chrome/test/unit \
 src/courgette/testdata \
 src/ipc/data \
 src/net/data \
 src/net/tools \
 src/third_party/{pyftpdlib,python_24,tlslite,hunspell/dictionaries/en-US*.bdic} \
"

# Skip chrome itself for the moment, it makes the download huge.
# src/chrome/Debug/chrome.{dll,exe} \
# src/chrome/Debug/chrome_dll.pdb \
# src/chrome/Debug/chrome_exe.pdb \

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
 FILES="$FILES src/chrome/Debug/$test.{exe,pdb} " 
done

FILES=`eval echo $FILES`

# Exclude these large subdirectories of src/chrome/test/data
cat > toobig.txt <<_EOF_
firefox2_nss_mac
firefox3_nss_mac
layout_tests
profiles
safari_import
safe_browsing
sunspider
v8_benchmark
_EOF_

tar -cjvf chromium-tests.tar.bz2 \
 --exclude=.svn --exclude="*.user" --exclude="*.pyc" --exclude-from toobig.txt \
 $FILES


