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

usage() {
  cat <<_EOF_
Usage: sh chromium-runtests.sh [--options] [suite ...]
Runs chromium tests on Windows or Wine, optionally with valgrind.
Stdout/stderr saved to logs/ directory.  (The tests themselves
may save logs next to their executables in src/Debug.)
Options:
  --individual     - run tests individually 
  --just-crashes   - run only tests epected to crash
  --just-fails     - run only tests epected to fail
  --just-flaky     - run only tests epected to fail sometimes
  --just-hangs     - run only tests epected to hang
  --list-failures  - show list of expected failures
  --loops N        - run tests N times
  -n               - dry run, only show what will be done
  --valgrind       - run the tests under valgrind
  --winedebug chan - e.g. --windebug +relay,+seh
Currently supported suites:
app_unittests base_unittests courgette_unittests googleurl_unittests
ipc_tests media_unittests net_unittests printing_unittests sbox_unittests
sbox_validation_tests setup_unittests tcmalloc_unittests unit_tests
Default is to run all suites.  It takes about five minutes to run them all
together, 22 minutes to run them all individually.
_EOF_
 exit 1
}

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

THE_VALGRIND_CMD="/usr/local/valgrind-10903/bin/valgrind \
--gen-suppressions=all \
--leak-check=full \
--num-callers=25 \
--show-possible=no \
--suppressions=../../../../../valgrind/valgrind-suppressions \
--trace-children=yes \
--track-origins=yes \
--workaround-gcc296-bugs=yes \
"

# Filter out known failures
# Avoid tests that hung, failed, or crashed on windows in Dan's reference run,
# or which fail in a way we don't care about on Wine,
# or which hang or crash on wine in a way that keeps other tests from running.
# Also lists url of bug report, if any.
# Format with
#  sh chromium-runtests.sh --list-failures | sort |  awk '{printf("%-21s %-20s %-52s %s\n", $1, $2, $3, $4);}'

list_known_failures() {
cat <<_EOF_
base_unittests        dontcare             BaseWinUtilTest.FormatMessageW                       
base_unittests        dontcare             FileUtilTest.CountFilesCreatedAfter                  
base_unittests        dontcare             FileUtilTest.GetFileCreationLocalTime                
base_unittests        dontcare-winfail     TimeTicks.HighResNow                                 fails if run individually on windows
base_unittests        dontcare             WMIUtilTest.*                                        
base_unittests        fail                 HMACTest.HMACObjectReuse                             http://bugs.winehq.org/show_bug.cgi?id=20340
base_unittests        fail                 HMACTest.HmacSafeBrowsingResponseTest                http://bugs.winehq.org/show_bug.cgi?id=20340
base_unittests        fail                 HMACTest.RFC2202TestCases                            http://bugs.winehq.org/show_bug.cgi?id=20340
base_unittests        fail                 PEImageTest.EnumeratesPE                             
base_unittests        fail                 StackTrace.OutputToStream                            
base_unittests        flaky-dontcare       StatsTableTest.MultipleProcesses                     http://bugs.winehq.org/show_bug.cgi?id=20606
base_unittests        hang-dontcare        DirectoryWatcherTest.*                               
ipc_tests             flaky                IPCChannelTest.ChannelTest                           
ipc_tests             flaky                IPCChannelTest.SendMessageInChannelConnected         
ipc_tests             hang                 IPCSyncChannelTest.*                                 http://bugs.winehq.org/show_bug.cgi?id=20390
media_unittests       crash                FFmpegGlueTest.OpenClose                             
media_unittests       crash                FFmpegGlueTest.Read                                  
media_unittests       crash                FFmpegGlueTest.Seek                                  
media_unittests       crash                FFmpegGlueTest.Write                                 
net_unittests         fail                 HTTPSRequestTest.HTTPSExpiredTest                    
net_unittests         fail                 HTTPSRequestTest.HTTPSGetTest                        
net_unittests         fail                 HTTPSRequestTest.HTTPSMismatchedTest                 
net_unittests         fail                 ProxyScriptFetcherTest.ContentDisposition            
net_unittests         fail                 ProxyScriptFetcherTest.Encodings                     
net_unittests         fail                 ProxyScriptFetcherTest.Hang                          
net_unittests         fail                 ProxyScriptFetcherTest.HttpMimeType                  
net_unittests         fail                 ProxyScriptFetcherTest.NoCache                       
net_unittests         fail                 ProxyScriptFetcherTest.TooLarge                      
net_unittests         hang                 SSLClientSocketTest.*                                
sbox_unittests        fail                 JobTest.ProcessInJob                                 
sbox_unittests        fail                 JobTest.TestCreation                                 
sbox_unittests        fail                 JobTest.TestDetach                                   
sbox_unittests        fail                 JobTest.TestExceptions                               
sbox_unittests        fail                 RestrictedTokenTest.AddAllSidToRestrictingSids       
sbox_unittests        fail                 RestrictedTokenTest.AddMultipleRestrictingSids       
sbox_unittests        fail                 RestrictedTokenTest.AddRestrictingSid                
sbox_unittests        fail                 RestrictedTokenTest.AddRestrictingSidCurrentUser     
sbox_unittests        fail                 RestrictedTokenTest.AddRestrictingSidLogonSession    
sbox_unittests        fail                 RestrictedTokenTest.DefaultDacl                      
sbox_unittests        fail                 RestrictedTokenTest.DeleteAllPrivileges              
sbox_unittests        fail                 RestrictedTokenTest.DeleteAllPrivilegesException     
sbox_unittests        fail                 RestrictedTokenTest.DeletePrivilege                  
sbox_unittests        fail                 RestrictedTokenTest.DenyOwnerSid                     
sbox_unittests        fail                 RestrictedTokenTest.DenySid                          
sbox_unittests        fail                 RestrictedTokenTest.DenySids                         
sbox_unittests        fail                 RestrictedTokenTest.DenySidsException                
sbox_unittests        fail                 RestrictedTokenTest.ResultToken                      
sbox_unittests        fail                 ServiceResolverTest.PatchesServices                  
sbox_unittests        flaky                IPCTest.ClientFastServer                             
sbox_validation_tests fail                 ValidationSuite.*                                    
unit_tests            crash                SafeBrowsingProtocolParsingTest.TestGetHashWithMac   
unit_tests            dontcare-hangwin     UtilityProcessHostTest.ExtensionUnpacker             
unit_tests            dontcare             SpellCheckTest.SpellCheckText                        
unit_tests            fail                 DownloadManagerTest.TestDownloadFilename             
unit_tests            fail                 EncryptorTest.EncryptionDecryption                   http://bugs.winehq.org/show_bug.cgi?id=20495
unit_tests            fail                 EncryptorTest.String16EncryptionDecryption           http://bugs.winehq.org/show_bug.cgi?id=20495
unit_tests            fail                 ImporterTest.IEImporter                              
unit_tests            fail                 RenderViewTest.InsertCharacters                      
unit_tests            fail                 RenderViewTest.OnPrintPages                          
unit_tests            fail                 RenderViewTest.PrintLayoutTest                       
unit_tests            fail                 RenderViewTest.PrintWithIframe                       
unit_tests            fail                 RenderViewTest.PrintWithJavascript                   
unit_tests            fail                 SafeBrowsingProtocolParsingTest.TestVerifyChunkMac   
unit_tests            fail                 SafeBrowsingProtocolParsingTest.TestVerifyUpdateMac  
unit_tests            fail                 URLFetcherBadHTTPSTest.BadHTTPSTest                  
unit_tests            fail                 URLFetcherCancelTest.ReleasesContext                 
unit_tests            fail                 URLFetcherProtectTest.ServerUnavailable              
unit_tests            hang                 ChromePluginTest.*                                   
_EOF_
}

init_runtime() {
  if test "$WINDIR" = ""
  then
    WINE=${WINE:-$HOME/wine-git/wine}
    WINESERVER=${WINESERVER:-$HOME/wine-git/server/wineserver}
    WINEPREFIX=${WINEPREFIX:-$HOME/.wine-chromium-tests}
    export WINE WINEPREFIX
    $dry_run rm -rf $WINEPREFIX
    $dry_run $WINE winemine &
    $dry_run sleep 1
    $dry_run test -f winetricks || wget http://kegel.com/wine/winetricks
    $dry_run sh winetricks nocrashdialog corefonts gecko > /dev/null
  fi
}

shutdown_runtime() {
  if test "$WINDIR" = ""
  then
    $dry_run $WINESERVER -k
  fi
}

# Looks up tests from our list of known bad tests.  If $2 is not '.', picks tests expected to fail in a particular way.
get_test_filter()
{
  mysuite=$1
  myfilter=$2
  list_known_failures | tee tmp.1 |
   awk '$1 == "'$mysuite'" && /'$myfilter'/ {print $3}' |tee tmp.2 |
   tr '\012' : |tee tmp.3 |
   sed 's/:$/\n/'
}

# Expands a gtest filter spec to a plain old list of tests separated by whitespace
expand_test_list()
{
  mysuite=$1    # e.g. base_unittests
  myfilter=$2   # existing gtest_filter specification with wildcard
  # List just the tests matching $myfilter, separated by colons
  $WINE ./$mysuite.exe --gtest_filter=$myfilter --gtest_list_tests |
   tr -d '\015' |
   grep -v FLAKY |
   perl -e 'while (<STDIN>) { chomp; if (/^[A-Z]/) { $testname=$_; } elsif (/./) { s/\s*//; print "$testname$_\n"} }'
}

# Parse arguments

do_individual=no
announce=true
dry_run=
fail_filter="."
SUITES=
VALGRIND_CMD=
want_fails=no
loops=1
winedebug=

while test "$1" != ""
do
  case $1 in
  --individual) do_individual=yes;;
  --just-crashes) fail_filter="crash"; want_fails=yes;;
  --just-fails) fail_filter="fail"; want_fails=yes;;
  --just-flaky) fail_filter="flaky"; want_fails=yes;;
  --just-hangs) fail_filter="hang"; want_fails=yes;;
  --list-failures) list_known_failures; exit 0;;
  --list-failures-html) list_known_failures | sed 's,http://\(.*\),<a href="http://\1">\1</a>,;s/$/<br>/' ; exit 0;;
  --loops) loops=$2; shift;;
  -n) dry_run=true; announce=echo ;;
  --valgrind) VALGRIND_CMD="$THE_VALGRIND_CMD";;
  --winedebug) winedebug=$2; shift;;
  -*) usage; exit 1;;
  *) SUITES="$SUITES $1" ;;
  esac
  shift
done

if test "$SUITES" = ""
then
   SUITES="$SUITES_1 $SUITES_10 $SUITES_100 $SUITES_1000"
fi

set -x
set -e

cd src/chrome/Debug

init_runtime

i=1
while test $i -le $loops
do
  for suite in $SUITES
  do
    mkdir -p ../../../logs

    expected_to_fail="`get_test_filter $suite $fail_filter`"
    case $want_fails in
    no)  filterspec=-$expected_to_fail ;;
    yes) filterspec=$expected_to_fail ;;
    esac

    case $do_individual in
    no)
      $announce $VALGRIND_CMD $WINE ./$suite.exe --gtest_filter=$filterspec 
      WINEDEBUG=$winedebug $dry_run  \
                $VALGRIND_CMD $WINE ./$suite.exe --gtest_filter=$filterspec > ../../../logs/$suite-$i.log 2>&1 || true
      ;;
    yes)
      for test in `expand_test_list $suite $filterspec`
      do
        $announce $VALGRIND_CMD $WINE ./$suite.exe --gtest_filter="$test" 
        WINEDEBUG=$winedebug $dry_run  \
                  $VALGRIND_CMD $WINE ./$suite.exe --gtest_filter="$test" > ../../../logs/$suite-$test-$i.log 2>&1 || true
      done
      ;;
    esac
  done
  i=`expr $i + 1`
done

shutdown_runtime
