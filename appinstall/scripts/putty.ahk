;
; AutoHotKey Test Script for PuTTY
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
; Currently, only downloads PuTTY, verifies the download, runs it, verifies the
; window exists, and exits. Eventually, add more tests, for, e.g., treeview controls.
; If a public ssh server could be found, that would be great to test as well.
testname=putty

; Global variables
APPINSTALL=%SYSTEMDRIVE%\appinstall
APPINTALL_TEMP=%TEMP%\appinstall
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

; Download putty, run it, verify the window exist, and exit.
; Will probably add more eventually, but A) That depends on having an SSH server available for public use, which is unlikely
; and B) I want to get a large variety of simple tests in before making them more complex. Shotgun approach => more bugs to find/prevent.

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
DOWNLOAD("http://the.earth.li/~sgtatham/putty/latest/x86/putty.exe", "putty.exe", "ae7734e7a54353ab13ecba780ed62344332fbc6f")

ErrorLevel=
Run, putty.exe,
ERROR_TEST("PuTTY failed to run.", "PuTTY claimed to start up fine.")

Window_wait("PuTTY Configuration","Specify the destination you want to connect to")
ERROR_TEST("PuTTY window never appeared.", "PuTTY window appeared.")

; Exit now. Will probably add more tests in between here. PuTTY's got a lot of comctl32 stuff that may be useful for testing.
ControlClick, Button2, PuTTY Configuration

ERROR_TEST("Exiting PuTTY failed.", "PuTTY claimed to exit.")

If Winexist, PuTTY Configuration
{
    FileAppend, PuTTY didn't exit for some reason. Test failed.`n, %OUTPUT%
}
Else
{
FileAppend, PuTTY exited successfully. Test passed.`n, %OUTPUT%
}

exit 0