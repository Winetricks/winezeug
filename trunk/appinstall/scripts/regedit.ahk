;
; AutoHotKey Test Script - Regedit
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

/* TODO:
Basic tests
Import a (variety of) keys
Import a non-existant key
Export (variety of) keys
(above should be with gui and cli)

http://bugs.winehq.org/show_bug.cgi?id=17242
http://bugs.winehq.org/show_bug.cgi?id=18170
http://bugs.winehq.org/show_bug.cgi?id=18554
http://bugs.winehq.org/show_bug.cgi?id=18631
*/

#Include helper_functions
#Include init_test

; First, make sure it launches:
Run, regedit.exe
ERROR_TEST("Launching regedit gave an error.","Regedit launched fine.")
WINDOW_WAIT("Registry Editor")
CLOSE("Registry Editor")
Sleep 500
WIN_EXIST_TEST("Registry Editor")


; Try with an existing registry key:

; First, delete the key, just in case
RegDelete, HKEY_CURRENT_USER, Test, test123 ; Don't check LastError, since this likely fails.

FileAppend, 
(
REGEDIT4

[HKEY_CURRENT_USER\Test]
"test123"="456"

), test.reg

Run, regedit.exe test.reg
TODO_WINDOW_WAIT("Registry Editor","19526","Are you sure you want to add the information in test.reg to the registry?")
IfWinExist, Registry Editor
{
    ControlClick, &Yes, Registry Editor
}
TODO_WINDOW_WAIT("Registry Editor","19526","Information in test.reg has been successfully entered into the registry.")
IfWinExist, Registry Editor
{
    ControlClick, OK, Registry Editor
}
RegRead, result, HKEY_CURRENT_USER, Test, test123
ERROR_TEST("Reading test key failed.","Reading test key went fine.")
If result = 456
{
    FileAppend, Test key matches imported key. Test passed.`n, %OUTPUT%
}
Else
{
    FileAppend, Test key does not match imported key. Test failed.`n, %OUTPUT%
}

RegDelete, HKEY_CURRENT_USER, Test, test123
FileDelete, test.reg, 1
ERROR_TEST("Deleting test.reg failed.","Deleting test.reg worked fine.")

; Try with a non-existant key:
FileDelete, notreal.reg, 1 ; Just in case

Run, regedit.exe notreal.reg
TODO_WINDOW_WAIT("Registry Editor","19526","Are you sure you want to add the information in notreal.reg to the registry?")
IfWinExist, Registry Editor
{
    ControlClick, &Yes, Registry Editor
}
TODO_WINDOW_WAIT("Registry Editor","19526","Cannot import notreal.reg: Error opening the file. There may be a disk or file system error.")
IfWinExist, Registry Editor
{
    ControlClick, OK, Registry Editor
}

; Try with a binary(non-registry) file:
Run, regedit.exe regedit.exe
TODO_WINDOW_WAIT("Registry Editor","19526","Are you sure you want to add the information in regedit.exe to the registry?")
IfWinExist, Registry Editor
{
    ControlClick, &Yes, Registry Editor
}
TODO_WINDOW_WAIT("Registry Editor","19526","Cannot import regedit.exe: The specified file is not a registry script.")
IfWinExist, Registry Editor
{
    ControlClick, OK, Registry Editor
}

FileAppend, TEST COMPLETE.`n, %OUTPUT%

exit 0
