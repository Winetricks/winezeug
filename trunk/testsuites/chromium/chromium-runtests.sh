#!/bin/sh
# chromium-runtests.sh [testsuite]
# Script to run a respectable subset of Chromium's test suite
# (excepting parts that run the browser itself, and excepting layout tests).
# Run from parent of src directory.
# By default, runs all test suites.  If you specify one testsuite 
# (e.g. base_unittests), it only runs that one.
#
# Chromium's test suite uses gtest, so each executable obeys the options
# documented in the wiki at http://code.google.com/p/googletest
# In particular, you can run a single test with --gtest_filter=Foo.Bar,
# and get a full list of tests in each exe with --gtest_list_tests.
#
# Before running the tests, regardless of operating system:
# 1) Make sure your system has at least one printer installed,
# or printing_unittests and unit_tests' PrintJobTest.SimplePrint
# will fail.  A fake printer is fine, nothing will be printed.
# 2) Install the test cert as described at
# http://bugs.winehq.org/show_bug.cgi?id=20370
# or net_unittests' HTTPSRequestTest.*, SSLClientSocketTest.*
# and others may fail.
#
# Chrome doesn't start without the --no-sandbox
# option in wine, so skip test suites that invoke it directly until I
# figure out how to jam that in there.

set -x
set -e

# Tests, grouped by how long they take to run
# Skip ones that require chrome itself for the moment
SUITES_1="googleurl_unittests printing_unittests sbox_validation_tests setup_unittests"
#SUITES_10="app_unittests courgette_unittests ipc_tests reliability_tests sbox_integration_tests sbox_unittests tab_switching_test tcmalloc_unittests url_fetch_test"
SUITES_10="app_unittests courgette_unittests ipc_tests sbox_unittests tcmalloc_unittests"
#SUITES_100="automated_ui_tests installer_util_unittests media_unittests nacl_ui_tests net_perftests net_unittests plugin_tests sync_unit_tests"
SUITES_100="media_unittests net_unittests"
#SUITES_1000="base_unittests interactive_ui_tests memory_test page_cycler_tests perf_tests test_shell_tests unit_tests"
SUITES_1000="base_unittests unit_tests"
#SUITES_10000="ui_tests startup_tests"

# Caller can specify one test suite
if test "$1" != ""
then
   SUITES="$1"
else
   SUITES="$SUITES_1 $SUITES_10 $SUITES_100 $SUITES_1000"
fi

if test "$WINDIR" = ""
then
    WINE=${WINE:-$HOME/wine-git/wine}
    WINEPREFIX=${WINEPREFIX:-$HOME/.wine-chromium-tests}
    export WINE WINEPREFIX
    rm -rf $WINEPREFIX
    $WINE notepad &
    sleep 1
    test -f winetricks || wget http://kegel.com/wine/winetricks
    sh winetricks nocrashdialog corefonts gecko
fi

cd src/chrome/Debug

# Filter out known failures
# Avoid tests that hung or failed on windows in Dan's reference run,
# or which fail in a way we don't care about on Wine
#
# The following tests fail on Wine, but we don't care much:
# Chrome doesn't really use WMI (maybe in the uninstaller):
#  WMIUtilTest.*
# Probably just because wine doesn't do file creation times yet:
#  base_unittests: FileUtilTest.CountFilesCreatedAfter,
#  FileUtilTest.GetFileCreationLocalTime, DirectoryWatcherTest.*
# The following test fails on Wine because of a trivial message difference:
#  base_unittests: BaseWinUtilTest.FormatMessageW
# Tests that hang on Wine, probably due to a bug in chrome:
#  net_unittests: DiskCacheEntryTest.CancelSparseIO (test hangs if disk I/O never blocks)
#  
# Tests that we want to work on wine, but which currently hang or crash:
#  ipc_tests: IPCSyncChannelTest.*
#  net_unittests: SSLClientSocketTest.*
#  unit_tests: SafeBrowsingProtocolParsingTest.TestGetHashWithMac

get_gtest_filter()
{
   case $1 in
   app_unittests) echo --gtest_filter=-\
IconUtilTest.TestIconToBitmapInvalidParameters:\
IconUtilTest.TestCreateSkBitmapFromHICON:\
IconUtilTest.TestCreateIconFile ;;

   base_unittests) echo --gtest_filter=-\
BaseWinUtilTest.FormatMessageW:\
DirectoryWatcherTest.*:\
FileUtilTest.CountFilesCreatedAfter:\
FileUtilTest.GetFileCreationLocalTime:\
WMIUtilTest.* ;;

   courgette_unittests) echo --gtest_filter=-\
ImageInfoTest.All ;;

   ipc_tests) echo --gtest_filter=-\
IPCSyncChannelTest.* ;;

   media_unittests) echo --gtest_filter=-\
YUVConvertTest.YV12:\
YUVConvertTest.YV16:\
YUVScaleTest.YV12:\
YUVScaleTest.YV16:\
FileDataSourceTest.OpenFile:\
FileDataSourceTest.ReadData:\
WinAudioTest.PushSourceFile16KHz ;;

   net_unittests) echo --gtest_filter=-\
DiskCacheEntryTest.CancelSparseIO:\
SSLClientSocketTest.*:\
X509CertificateTest.PaypalNullCertParsing ;;

   unit_tests) echo --gtest_filter=-\
ChromePluginTest.*:\
HistoryProfileTest.TypicalProfileVersion:\
ProfileManagerTest.CopyProfileData:\
SafeBrowsingProtocolParsingTest.TestGetHashWithMac:\
SpellCheckTest.GetAutoCorrectionWord_EN_US:\
SpellCheckTest.SpellCheckStrings_EN_US:\
SpellCheckTest.SpellCheckSuggestions_EN_US:\
SpellCheckTest.SpellCheckText:\
TabContentsTest.WebKitPrefs:\
UtilityProcessHostTest.ExtensionMessagesDisconnect:\
UtilityProcessHostTest.ExtensionUnpacker ;;
   esac
}

# Plain old runs, without valgrind
# Optional: run tests many times to look for flaky failures
i=1
while test $i -lt 10
do
  for suite in $SUITES
  do
   mkdir -p ../../../logs
   if true
   then
     # Run the whole suite at once
     $WINE ./$suite.exe `get_gtest_filter $suite` > ../../../logs/$suite-$i.log 2>&1 || true
   else
     # Run tests in small groups (this gets more useful with valgrind)
     mkdir -p ../../../logs/$suite
     mkdir -p ../../../logs/$suite/run$i
     $WINE ./$suite.exe --gtest_list_tests | tr -d '\015' | grep '\.$' | tr -d . > $suite.txt
     for test in `cat $suite.txt`
     do
        # todo: use get_gtest_filter here
        $WINE ./$suite.exe --gtest_filter="$test.*" > ../../../logs/$suite/run$i/$test.log 2>&1 || true
     done
   fi
  done
  i=`expr $i + 1`
done
