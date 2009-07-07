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

; Test info:
; Tests for bug 18574.
; Note: This (along with the other tests) is normally ran from a shell script wrapper.
; While normally this shouldn't make a difference, this application is one of the ones
; that needs winetricks. So if you run it independently, be sure to account for that.

; Winetricks dependencies:
; 'winetricks mfc42' - application requirement

testname=win92

#Include helper_functions
#Include init_test

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

SHA1("bbe8956460b1084b42305df8286a4cb7119b52b5", "Win92.exe")
SHA1("85e10417e6a814e44b2f09610d02d7c527db87bd", "WinXXCommon.dll")

Run, Win92.exe
WAIT_CRASH_FATAL("Win92.exe", 18574)

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

WIN_EXIST_TEST("Win92 V00.46")

CLEANUP()
exit 0