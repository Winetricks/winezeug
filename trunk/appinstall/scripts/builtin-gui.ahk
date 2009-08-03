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

; This script is a bit of a special case...it tests all of wine's built in programs.
; Some of these don't follow their window's counterparts perfectly, or at all, so
; 'bug for bug' compatability is not extremely important here. What _IS_ important,
; is that what works in wine now keeps working in the future, and to catch any TODO_FIXED bugs.

; Note: May end up splitting notepad/wordpad/winhelp.exe off into their own
; scripts for more extensive tests in the future.

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
WinWait, %windowname%, , 15  ; Give programs up to 15 seconds to run
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
BUILTIN_TEST("oleview","OleView")
BUILTIN_TEST("progman","Program Manager")
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
Sleep 500 ; Prevent race condition
WIN_EXIST_TEST("Open")
IfWinExist, ERROR ; Doesn't appear on Windows
    {
        FileAppend, ERROR dialog appeared. Bug 19081 TODO_FAILED.`n, %OUTPUT%
        CLOSE("ERROR")
    }
    Else
    {
        FileAppend, ERROR dialog didn't appear. Bug 19081 TODO_FIXED.`n, %OUTPUT%
    }

Sleep 500

Run, winhlp32
ERROR_TEST("Running 32bit winhelp reported an error.", "32bit winhelp launched fine.")
WINDOW_WAIT("Wine Help")
FORCE_CLOSE("Wine Help") ; Force closing winhelp
Sleep 500
WIN_EXIST_TEST("Open")
IfWinExist, ERROR ; Doesn't appear on Windows
    {
        FileAppend, ERROR dialog appeared. Bug 19081 TODO_FAILED.`n, %OUTPUT%
        CLOSE("ERROR")
    }
    Else
    {
        FileAppend, ERROR dialog didn't appear. Bug 19081 TODO_FIXED.`n, %OUTPUT%
    }

; AJ won't accept installing these globally, so we have to run them from the tree.
; If someone doesn't have $HOME/wine-git they'll be skipped.
IfNotExist, %A_MyDocuments%\wine-git
    {
        FileAppend, wine-git tree not found. Skipping view and cmdlgtst tests.`n, %OUTPUT%
        exit 0
    }
SetWorkingDir, %A_MyDocuments%\wine-git
ERROR_TEST("Setting work directory to git tree failed.", "Set work directory to git tree successfully.")
BUILTIN_TEST("programs\view\view.exe.so","Regular Metafile Viewer")
BUILTIN_TEST("programs\cmdlgtst\cmdlgtst.exe.so","Cmdlgtst Window")

; Make sure bug 15367 doesn't regress.
Run, notepad
ERROR_TEST("Running notepad reported an error.", "Notepad launched fine.")
WINDOW_WAIT("Untitled - Notepad")
Send, {ALT}Hh ; Activates, 'Help', 'Help on Help'
WINDOW_WAIT("ERROR","Cannot find 'winhelp.hlp'. Do you want to find this file yourself?")
FileAppend, Using 'help on help' didn't crash notepad/winhlp32. Test passed.`n, %OUTPUT%
ControlClick, &No, ERROR, Cannot find 'winhelp.hlp'. Do you want to find this file yourself?
CLOSE("Untitled - Notepad")
Sleep 500
WIN_EXIST_TEST("Untitled - Notepad")
WIN_EXIST_TEST("ERROR")

FileAppend, TEST COMPLETE.`n, %OUTPUT%

exit 0
