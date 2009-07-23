;
; AutoHotKey Test Script - Notepad
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

testname=notepad

#Include helper_functions
#Include init_test

; First, make sure it launches:
Run, notepad.exe
ERROR_TEST("Launching notepad gave an error.","Notepad launched fine.")
WINDOW_WAIT("Untitled - Notepad")
CLOSE("Untitled - Notepad")
Sleep 500
WIN_EXIST_TEST("Untitled - Notepad")

; Now try with an existing text file:
IfExist, basic_test.txt
{
    FileDelete, basic_test.txt
    ERROR_TEST("File basic_test.txt failed to be deleted.", "File basic_test.txt deleted fine.")
}
FileAppend, This is a basic text file.`n, basic_test.txt
Run, notepad.exe basic_test.txt
ERROR_TEST("Launching notepad basic_test.txt gave an error.","Notepad basic_test.txt launched fine.")
WINDOW_WAIT("basic_test.txt - Notepad")
CLOSE("basic_test.txt - Notepad")
Sleep 500
WIN_EXIST_TEST("basic_test.txt - Notepad")
FileDelete, basic_test.txt
ERROR_TEST("File basic_test.txt failed to be deleted.", "File basic_test.txt deleted fine.")

; Try with a non-existing text file, choosing 'yes' to create a new file.
IfExist, not_a_real_file_yes.txt
{
    FileDelete, not_a_real_file_yes.txt
    ERROR_TEST("File not_a_real_file_yes.txt failed to be deleted.", "File not_a_real_file_yes.txt deleted fine.")
}
Run, notepad.exe not_a_real_file_yes.txt
ERROR_TEST("Launching notepad not_a_real_file_yes.txt gave an error.","Notepad not_a_real_file_yes.txt launched fine.")
WINDOW_WAIT("ERROR","File 'not_a_real_file_yes.txt' does not exist.")
ControlClick, &Yes, ERROR, File 'not_a_real_file_yes.txt' does not exist.
WINDOW_WAIT("not_a_real_file_yes.txt - Notepad")
CLOSE("not_a_real_file_yes.txt - Notepad")
Sleep 500
WIN_EXIST_TEST("not_a_real_file_yes.txt - Notepad")
FileDelete, not_a_real_file_yes.txt
ERROR_TEST("File not_a_real_file_yes.txt failed to be deleted.", "File not_a_real_file_yes.txt deleted fine.")

; Try with a non-existing text file, choosing 'no' to not create a new file.
IfExist, not_a_real_file_no.txt
{
    FileDelete, not_a_real_file_no.txt
    ERROR_TEST("File not_a_real_file_no.txt failed to be deleted.", "File not_a_real_file_no.txt deleted fine.")
}
Run, notepad.exe not_a_real_file_no.txt
ERROR_TEST("Launching notepad not_a_real_file_no.txt gave an error.","Notepad not_a_real_file_no.txt launched fine.")
WINDOW_WAIT("ERROR","File 'not_a_real_file_no.txt' does not exist.")
ControlClick, &No, ERROR, File 'not_a_real_file_no.txt' does not exist.
WINDOW_WAIT("Untitled - Notepad")
CLOSE("Untitled - Notepad")
Sleep 500
WIN_EXIST_TEST("Untitled - Notepad")

; Try with a non-existing text file, choosing 'cancel' to exit.
IfExist, not_a_real_file_cancel.txt
{
    FileDelete, not_a_real_file_cancel.txt
    ERROR_TEST("File not_a_real_file_cancel.txt failed to be deleted.", "File not_a_real_file_cancel.txt deleted fine.")
}
Run, notepad.exe not_a_real_file_cancel.txt
ERROR_TEST("Launching notepad not_a_real_file_cancel.txt gave an error.","Notepad not_a_real_file_cancel.txt launched fine.")
WINDOW_WAIT("ERROR","File 'not_a_real_file_cancel.txt' does not exist.")
ControlClick, &Cancel, ERROR, File 'not_a_real_file_cancel.txt' does not exist.
Sleep 1000

; Test for bug 8166
Process, Close, notepad.exe ; There shouldn't be one running, but just in case. See below for why.
If GetLastError
{
    FileAppend, Killed a notepad process before testing bug 8166. Unexpected. Test failed.`n, %OUTPUT%
}
DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
DOWNLOAD("http://bugs2.winehq.org/attachment.cgi?id=5917", "testfile32k.txt", "cb53db4e70eec3da399c62af80281730d0f07a88")
Run, notepad.exe testfile32k.txt
ERROR_TEST("Launching notepad testfile32k.txt gave an error.","Notepad testfile32k.txt launched fine.")
WINDOW_WAIT("testfile32k.txt - Notepad")
ControlClick, Edit1, testfile32k.txt - Notepad
ControlSend, Edit1, {PgUp}{PgUp}{PgUp}{PgUp}{PgUp}{PgUp}{PgUp}{PgUp}{PgDn}{PgDn}{PgDn}{PgDn}{PgDn}{PgDn}{PgDn}{PgDn}{PgDn}, testfile32k.txt - Notepad ; This should crash notepad

; Apparently notepad.exe isn't issuing a LASTERROR if it crashes. It's crashing in X, so that may be why...hm.
Sleep 2000
Process, Exist, notepad.exe ; If one of the earlier notepad processes didn't exit, may have a conflict here.
pid:=errorlevel
IfWinExist, ahk_pid %pid%
{
    FileAppend, Notepad didn't crash. Bug 8166 TODO_FIXED.`n, %OUTPUT%
    CLOSE("testfile32k.txt - Notepad")
}
Else
{
    FileAppend, Notepad crashed. Bug 8166 TODO_FAILED.`n, %OUTPUT%
}

; Test a really big file (100K)
IfExist, large_file.txt
{
    FileDelete, large_file.txt
}
textsize=0
While %textsize% < 100
{
    FileAppend, Creating a really big file...`n, large_file.txt
    FileGetSize, textsize, large_file.txt, K
    If textsize >= 100
        break
}
Run notepad.exe large_file.txt
ERROR_TEST("Launching notepad large_file.txt gave an error.","Notepad large_file.txt launched fine.")
WINDOW_WAIT("large_file.txt - Notepad")
CLOSE("large_file.txt - Notepad")
Sleep 500
WIN_EXIST_TEST("large_file.txt - Notepad")

FileDelete, large_file.txt
ERROR_TEST("File large_file.txt failed to be deleted.", "File large_file.txt deleted fine.")

; FIXME: Add tests for files that exceed notepad's limit...I don't know what that limit is though.
; On Windows, used to be 45K, but as seen above, 55k works fine. I've opened files up to 300M with no problems.

exit 0
