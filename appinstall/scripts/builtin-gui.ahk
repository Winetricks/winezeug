;
; AutoHotKey Test Script - Builtin GUI Programs
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

; TODO: view (doesn't build an exe?) , winoldap.mod16 (what is it?)

; This script is a bit of a special case...it tests all of wine's built in programs.
; Some of these don't follow their window's counterparts perfectly, or at all, so
; 'bug for bug' compatability is not extremely important here. What _IS_ important,
; is that what works in wine now keeps working in the future, and to catch any TODO_FIXED bugs.

; Note: May end up splitting notepad/wordpad/winhelp.exe off into their own
; scripts for more extensive tests in the future.

testname=builtin-gui

#Include helper_functions
#Include init_test

; I know...a loop would be nice. But AHK doesn't support 'real' for loops.
; A helper function is the best I can do.
BUILTIN_TEST(program, windowname)
{
global OUTPUT
Run, %program%
    If GetLastError
    {
        FileAppend, %program% failed. Test failed.`n, %OUTPUT%
    }
    Else
    {
        FileAppend, %program% launched fine. Test passed.`n, %OUTPUT%
    }
    
WinWait, %windowname%
    if ErrorLevel
    {
        FileAppend, Launching %windowname% failed. Test failed.`n, %OUTPUT%
    }
    IfWinNotActive, %windowname%
        {
        WinActivate, %windowname%
        }
PostMessage, 0x112, 0xF060,,, %windowname%
    IfWinExist, %windowname%
    {
        WinKill, %windowname%
    }
If GetLastError
    {
        FileAppend, Closing %program% failed. Test failed.`n, %OUTPUT%
    }
    Else
    {
        FileAppend, Closing %program% went fine. Test passed.`n, %OUTPUT%
    }
}

BUILTIN_TEST("clock","Clock")
BUILTIN_TEST("control","Wine Control Panel")
BUILTIN_TEST("notepad","Untitled - Notepad")
BUILTIN_TEST("oleview","OleView")
BUILTIN_TEST("progman","Program Manager")
BUILTIN_TEST("regedit","Registry Editor")
BUILTIN_TEST("taskmgr","Task Manager")
BUILTIN_TEST("uninstaller","Add/Remove Programs")
BUILTIN_TEST("winefile","Wine File")
BUILTIN_TEST("winemine","WineMine")
BUILTIN_TEST("winver","About Wine")
BUILTIN_TEST("wordpad","Document - Wine Wordpad")
BUILTIN_TEST("write","Document - Wine Wordpad") ; Redundant, but just in case...

; Special cases, until bug 19081 is fixed.
Run, winevdm winhelp.exe
ERROR_TEST("Running 16bit winhelp reported an error.", "16bit winhelp launched fine.")
WINDOW_WAIT("Wine Help")
FORCE_CLOSE("Wine Help") ; Force closing winhelp
    WinWait, ERROR, , 10
    if ErrorLevel
    {
        FileAppend, Error window didn't appear. Bug 19081 fixed. TODO_FIXED.`n, %OUTPUT%
    }
    Else
    {
        FileAppend, Error window appeared. Bug 19081 TODO_FAILED.`n, %OUTPUT%
        FORCE_CLOSE("ERROR")
    }

Sleep 500

Run, winhlp32
ERROR_TEST("Running winhelp32 reported an error.", "Winhlp32 launched fine.")
WINDOW_WAIT("Wine Help")
FORCE_CLOSE("Wine Help")

    WinWait, ERROR, , 5
    if ErrorLevel
    {
        FileAppend, Error window didn't appear. Bug 19081 fixed. TODO_FIXED.`n, %OUTPUT%
    }
    Else
    {
        FileAppend, Error window appeared. Bug 19081 TODO_FAILED.`n, %OUTPUT%
        FORCE_CLOSE("ERROR")
    }

exit 0
