;
; AutoHotKey Test Script for Win92
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

#Include helper_functions

; Test info:
; Tests for bug 18574.
; Note: This (along with the other tests) is normally ran from a shell script wrapper.
; While normally this shouldn't make a difference, this application is one of the ones
; that needs winetricks. So if you run it independently, be sure to account for that.
testname=win92

; Winetricks dependencies:
; 'winetricks mfc42' - application requirement

; Global variables
APPINSTALL=%SYSTEMDRIVE%\appinstall
APPINSTALL_TEMP=%TEMP%\appinstall
IfNotExist, %APPINSTALL%
{
    FileCreateDir, %APPINSTALL%
}
IfNotExist, %APPINSTALL_TEMP%
{
    FileCreateDir, %APPINSTALL_TEMP%
}
SetWorkingDir, %APPINSTALL%

OUTPUT=%APPINSTALL%\%testname%-result.txt
; Start with a fresh log
IfExist, %OUTPUT%
{
    FileDelete, %OUTPUT%
}

; Download win92, unzip it, run it, verify the window exist, and exit.

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/unzip/unzip.exe", "unzip.exe", "ebfd20263e0a448e857967d4f32a2e85b2728923")
DOWNLOAD("http://www.starrsoft.com/freeware/win92/apps/Win92.zip", "win92.zip", "dc6d226fe20c949076eb6adb98fc851ca7157d04")

FileDelete, %APPINSTALL_TEMP%\win92\*
ERROR_TEST("Removing old temp files failed.", "Removed old temp files.")

Run, unzip.exe -d %APPINSTALL_TEMP%\win92 win92.zip

ERROR_TEST("Unzipping had some error.", "Unzipping went okay.")

; Sleep for a second to make sure a race condition in the unzip process doesn't break the test
Sleep 500

SetWorkingDir, %APPINSTALL_TEMP%\win92
ERROR_TEST("Setting work directory failed.", "Setting work directory went fine.")

SHA1("Win92.exe", "bbe8956460b1084b42305df8286a4cb7119b52b5")
SHA1("WinXXCommon.dll", "85e10417e6a814e44b2f09610d02d7c527db87bd")

Run, Win92.exe

; Workaround for the GUI debugger on wine. The crash is bug 18574.
; If the GUI debugger is disabled, the test will still fail below, but with a
; different error message. I don't think the tests need to account for both cases (yet anyway).
    WinWait, Program Error, , 5
    {
        IfWinExist, Program Error
        {    
            IfWinNotActive, Program Error
            {
                WinActivate, Program Error
            }
            ControlClick, Button1
            FileAppend, Win92 failed to launch. TODO_FAIL.`n, %OUTPUT%
            exit 0
        }
    }

; Probably should test ErrorLevel here, but in my test on windows, it keeps
; exiting even if there is no lasterror or I set it to NULL

Window_wait("Win92 V00.46", "Preprogrammed Search Bands", 5)

ERROR_TEST("Win92 window never appeared.", "Win92 launched fine.")

IfWinExist, Win92 V00.46
{
FileAppend, Win92 launched successfully. Check bug 18574. TODO_FIXED.`n, %OUTPUT%
}
WinClose, Win92 V00.46

ERROR_TEST("Exiting Win92 gave an error.", "Win92 claimed to exit fine.")

IfWinExist, Win92 V00.46
{
    FileAppend, Win92 didn't exit for some reason. Test failed.`n, %OUTPUT%
}
IfWinNotExist, Win92 V00.46
{
FileAppend, Win92 exited successfully. Test passed.`n, %OUTPUT%
}

CLEANUP()
exit 0