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

; Helper functions
DOWNLOAD(url, filename, sha1sum)
{
    global OUTPUT, APPINSTALL_TEMP, APPINSTALL
    IfNotExist, %filename%
    {
        UrlDownloadToFile, %url%, %filename%
    }
    FileAppend, %filename% already present. Not downloading.`n, %OUTPUT%

    If GetLastError
    {
        FileAppend, Downloading %filename% failed. Error 2. Test failed.`n, %OUTPUT%
        exit 2
    }
    
    TEMPFILE=%APPINSTALL_TEMP%\sha1sum.txt
    FileDelete, %TEMPFILE%
    RunWait, %comspec% /c %APPINSTALL%\sha1sum.exe %filename% >> %TEMPFILE%
    FileReadLine, checksum, %TEMPFILE%, 1
    FileDelete, %TEMPFILE%

    sha1sumgood = %sha1sum%  %filename%
    
    If (checksum != sha1sumgood)
    {
    FileAppend, %filename% checksum failed. Got %checksum%`, expected %sha1sum%. Error 3. Test failed.`n, %OUTPUT%
    exit 3
    }
}

SHA1(target)
{
    global OUTPUT, APPINSTALL_TEMP, APPINSTALL
    Filename=%APPINSTALL_TEMP%\sha1sum.txt
    FileDelete, %filename%
    RunWait, %comspec% /c %APPINSTALL%\sha1sum.exe %target% >> %filename%
    FileReadLine, checksum, %filename%, 1
    FileDelete, %filename%
    return %checksum%
}

WINDOW_WAIT(windowname, windowtext="", wintimeout=10)
{
    global OUTPUT
    WinWait, %WINDOWNAME%, %windowtext%, %wintimeout%
    if ErrorLevel
    {
        FileAppend, Launching %WINDOWNAME% failed. Test failed.`n, %OUTPUT%
        exit 1
    }
    IfWinNotActive, %WINDOWNAME%, %windowtext%
        {
        WinActivate, %WINDOWNAME%, %windowtext%
        }
}
; Test functions
CLEANUP()
{
    global APPINSTALL_TEMP
    FileRemoveDir, %APPINSTALL_TEMP%\win92, 1
}

; Download win92, unzip it, run it, verify the window exist, and exit.

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/unzip/unzip.exe", "unzip.exe", "ebfd20263e0a448e857967d4f32a2e85b2728923")
DOWNLOAD("http://www.starrsoft.com/freeware/win92/apps/Win92.zip", "win92.zip", "dc6d226fe20c949076eb6adb98fc851ca7157d04")

FileDelete, %APPINSTALL_TEMP%\win92\*
If ErrorLevel
{
    FileAppend, Removing old temp files failed. Test failed.`n, %OUTPUT%
    exit 1
}

Run, unzip.exe -d %APPINSTALL_TEMP%\win92 win92.zip

If ErrorLevel
{
    FileAppend, Unzipping had some error. Test failed.`n, %OUTPUT%
    CLEANUP()
    exit 1
}
Else
{
    FileAppend, Unzipping went okay. Test passed.`n, %OUTPUT%
}

; Sleep for a second to make sure a race condition in the unzip process doesn't break the test
Sleep 500

SetWorkingDir, %APPINSTALL_TEMP%\win92
If ErrorLevel
{
    FileAppend, %A_WorkingDir%`n, %OUTPUT%
    Msgbox workingdir failed
    FileAppend, Setting work directory failed. Test failed.`n, %OUTPUT%
    CLEANUP()
    exit 1
}
Else
{
    FileAppend, Setting work directory worked fine. Test passed.`n, %OUTPUT%
}

SHA1("Win92.exe")
If (checksum = "bbe8956460b1084b42305df8286a4cb7119b52b5  Win92.exe")
{
    FileAppend, Checksum of Win92.exe did not pass. Corrupted extraction or new version of file? Test failed.`n, %OUTPUT%
    CLEANUP()
    exit 1
}
FileAppend, Checksum of Win92.exe is correct. Test passed.`n, %OUTPUT%

SHA1("WinXXCommon.dll")
If (checksum = "85e10417e6a814e44b2f09610d02d7c527db87bd  WinXXCommon.dll")
{
    FileAppend, Checksum of WinXXCommon.dll did not pass. Corrupted extraction or new version of file? Test failed.`n, %OUTPUT%
    CLEANUP()
    exit 1
}
FileAppend, Checksum of WinXXCommon.dll is correct. Test passed.`n, %OUTPUT%

Run, Win92.exe

    WinWait, Program Error, , 5
    {
        IfWinNotActive, Program Error
        {
        WinActivate, Program Error
        }
        ControlClick, Button1
    }

; Probably should test ErrorLevel here, but in my test on windows, it keeps
; exiting even if there is no lasterror or I set it to NULL

Window_wait("Win92 V00.46", "Preprogrammed Search Bands", 5)
If ErrorLevel
{
    FileAppend, Win92 window never appeared. Error 1. Test failed.`n, %OUTPUT%
    CLEANUP()
    exit 1
}
IfWinExist, Win92 V00.46
{
FileAppend, Win92 launched successfully. Check bug 18574. TODO_FIXED.`n, %OUTPUT%
}
WinClose, Win92 V00.46

If ErrorLevel
{
    FileAppend, Exiting Win92 failed. Error 1. Test failed.`n, %OUTPUT%
    CLEANUP()
    exit 1
}

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