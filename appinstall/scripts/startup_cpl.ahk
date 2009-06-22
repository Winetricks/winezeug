;
; AutoHotKey Test Script for Startup CPL
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

testname=startup_cpl
#Include helper_functions
#Include init_test

; Download Startup CPL, unzip it, run it, verify the window exists, and exit.

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/unzip/unzip.exe", "unzip.exe", "ebfd20263e0a448e857967d4f32a2e85b2728923")
DOWNLOAD("http://www.mlin.net/files/StartupCPL_EXE.zip", "StartupCPL_EXE.zip", "9ecc5e6800862dac6deefaa8ffa9cde9be1e00b7")

FileDelete, %APPINSTALL_TEMP%\startup_cpl\*
ERROR_TEST("Removing old temp files failed.", "Removed old temp files.")

Run, unzip.exe -d %APPINSTALL_TEMP%\startup_cpl StartupCPL_EXE.zip

ERROR_TEST("Unzipping had some error.", "Unzipping went okay.")

; Prevent race condition
Sleep 500

SetWorkingDir, %APPINSTALL_TEMP%\startup_cpl
ERROR_TEST("Setting work directory failed.", "Setting work directory went fine.")

SHA1("7e799eec8a6dbc3688b1f2fb073b96b6931e9e5c", "Startup.exe")

Run, Startup.exe

Window_wait("Startup Control Panel 2.8 by Mike Lin", "Run these programs from the current user's Startup folder:", 5)

ERROR_TEST("Startup Control Panel window never appeared.", "Startup Control Panel launched fine.")

; Prevent race condition
Sleep 500

; Similar to Winclose(), but more forceful. I like forceful.
FORCE_CLOSE(Startup Control Panel 2.8 by Mike Lin)
ERROR_TEST("Exiting Startup Control Panel gave an error.", "Startup Control Panel claimed to exit fine.")

; Prevent race condition
Sleep 500

; While we should test if the window still exists, this test sporadically fails, even on windows.
; Disabling until I can make it consistent.
/*
IfWinExist, Startup Control Panel 2.8 by Mike Lin
{
    FileAppend, Startup Control Panel didn't exit for some reason. Test failed.`n, %OUTPUT%
}
IfWinNotExist, Startup Control Panel 2.8 by Mike Lin
{
FileAppend, Startup Control Panel 2.8 exited successfully. Test passed.`n, %OUTPUT%
}
*/

CLEANUP()
exit 0
