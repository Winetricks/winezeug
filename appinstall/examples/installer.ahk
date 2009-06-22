;
; AutoHotKey Example Test Script - Installer
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

; This is an example script for a regular installable application, e.g., Mozilla Firefox.

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
ERROR_TEST("Launching program had some error.", "Launching program went okay.")

; This can be a bit trickier. You'll need AutoHotKey's window spy utility to get the button names.
; It's helpful to also use the window text parameter of WINDOW_WAIT(), to prevent confusion over which
; window you're waiting to appear. Otherwise, you might skip one screen and break your test.
; You'll need one WINDOW_WAIT() and at least one ControlClick() per installer screen.
WINDOW_WAIT("Window title", "Window2 text")
ControlClick, Button2, Window title

WINDOW_WAIT("Window title", "Window2 text")
ControlClick, Button2, Window title

WINDOW_WAIT("Window title", "Window3 text")
ControlClick, Button2, Window title

; After you've installed, be sure to sha1sum the installed files.
Start by setting your work directory to the program's directory.
Setworkingdir, %ProgramFiles%\Program Name

; Now sha1sum all the files. The SHA1() function takes a sha1sum and a filename as paramters,
; and returns an error on failure or a silent success if the checksum's match. Be sure you sha1sum all
; files that are static. Exclude things like uninstall.log that depend on the username/date.
SHA1("bfb6c41cbb0bccb39b27afdfc258bf23e88e650d", "file1")
SHA1("5f617e8697a41838d7a55304d086587c32369891", "file2")
SHA1("0041b1e826d85356185242d2910c4448f610a67d", "file3")

; If all file's passed checksumming, run the installed program.
Run, program.exe

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