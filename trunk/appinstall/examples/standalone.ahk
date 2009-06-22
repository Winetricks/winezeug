;
; AutoHotKey Example Test Script - Standalone
;
; Copyright (C) 2009 Austin English
;
; This library is free software; you can redistribute it and/or
; modify it under the terms of the GNU Lesser General Public
; License as published by the Free Software Foundation; either
; version 2.1 of the License, or (at your option) any later version.
;
; This library is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; Lesser General Public License for more details.
;
; You should have received a copy of the GNU Lesser General Public
; License along with this library; if not, write to the Free Software
; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
;

; This is an example script for a standalone executable not requiring an installer,
; e.g., PuTTY.

; The testname is used in the logs to know what program this is. Just use a single
; word, and perhaps a version if there are multiple versions, e.g., 'firefox3' or 'winamp'.

testname=yourtestnamehere

; Don't mess with these includes. 'helper_functions' includes the helper functions used by the tests,
; and 'init_test' sets up the folders, removes old temp files, etc.
#Include helper_functions
#Include init_test

; Here is where you'll download your program. Leave the sha1sum program stuff alone, it's used to
; checksum your downloaded file.
DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
; Update the below info for your program. Be sure to leave the quotes!
DOWNLOAD("http://example.com/path/to/your/program.exe", "program_name.exe", "SHA1SUM")

; This will simply run the program. Be sure to change program_name.exe to your program's name.
Run, program_name.exe

; AutoHotKey isn't really designed to be used as a test framework, but there's an easy workaround.
; The ERROR_TEST will check if the LastError variable is set. If so, the previous command had an error.
; If not, it reported success. While this won't catch all errors, it's good to check anyway, and also serves
; as a logging mechanism.
ERROR_TEST("Running program reported an error.", "Program launched fine.")

; This is a helper function to wait for the program's window to appear. No quotes around the timeout. Example:
; Window_wait("Mozilla Firefox Start Page", "Bookmarks", 10)
; The 'window text' isn't just any text in the window, it must be a text element of the window itself. Use
; the Window Spy utility from AutoHotKey to determine the window text. The window text and timeout may also
; be left blank, for example:
; Window_wait("Mozilla Firefox Start Page")
Window_wait("Window title", "Window text", timeout in seconds)

; Check for last error, as you should for every test.
ERROR_TEST("Program window never appeared.", "Program window appeared fine.")

; This forces the window to close by sending the raw keycodes for "ALT+F4" to the program. No quotes needed.
; Be careful, since some programs will pop up a window asking to save, etc. You may need to account for this
; in your test(s).
FORCE_CLOSE(Window title)

; Again, check for last error, as you should for every test.
ERROR_TEST("Exiting Program gave an error.", "Program claimed to exit fine.")

; There may be a race condition between when the window is closed and when we try to verify it is closed.
; So pause for a while (the time is in milliseconds, so 500 = .5 second), to prevent that.
Sleep 500

; Now, verify the window did close. This function simply tests to see if the program's window is still open.
IfWinExist, Window Title
{
    FileAppend, Program didn't exit for some reason. Test failed.`n, %OUTPUT%
}
IfWinNotExist, Window Title
{
FileAppend, Program exited successfully. Test passed.`n, %OUTPUT%
}

; If you need to delete any temp files the program made, do that here:
FileDelete, *.tmp

; This deletes the Appinstall temp folder
CLEANUP()

; Exit and report success
exit 0