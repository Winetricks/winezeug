;
; AutoHotKey test script for ResHacker
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

testname=reshacker

#Include helper_functions
#Include init_test

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/unzip/unzip.exe", "unzip.exe", "ebfd20263e0a448e857967d4f32a2e85b2728923")
DOWNLOAD("http://www.angusj.com/resourcehacker/reshack.zip", "reshack.zip", "5f531b97591d3fab85cabd161642af8050927852")

Runwait, unzip.exe -d %APPINSTALL_TEMP%\reshack reshack.zip
ERROR_TEST("Unzipping reshack.zip had an error.","Unzipping reshack.zip went okay.")

Sleep 500
SetWorkingDir, %APPINSTALL_TEMP%\reshack
ERROR_TEST("Setting work directory had an error.","Setting work directory reshack.zip went okay.")

SHA1("f1b1197a4e04a580258d2dd9a21c99438b7e27d3","Dialogs.def")
SHA1("3d16fc3f59280628bf685fd7cee18e676720b9bd","ReadMe.txt")
SHA1("92854e8fdb152034e148de9175184ec71c643639","ResHacker.cnt")
SHA1("0284fd320f99f62aca800fb1251eff4c31ec4ed7","ResHacker.exe")
SHA1("1a91b366ecf64a7d8e62f2d44519277be80d36d9","ResHacker.hlp")
SHA1("a1a12f97a7cbe383421a8438a9fc04d231e251fa","Version_History.txt")

Run, ResHacker.exe
ERROR_TEST("Running ResHacker had an error.","Running ResHacker went okay.")

WINDOW_WAIT("Resource Hacker")
CLOSE("Resource Hacker")

Sleep 500
WIN_EXIST_TEST("Resource Hacker")

; Try running it with a resource:
Run, ResHacker.exe ResHacker.exe
ERROR_TEST("Running ResHacker with a resource had an error.","Running ResHacker with a resource went okay.")

WINDOW_WAIT("Resource Hacker")
CLOSE("Resource Hacker")

Sleep 500
WIN_EXIST_TEST("Resource Hacker")

; Removing the directory when we're in it isn't the best of plans...
SetWorkingDir, %APPINSTALL%

CLEANUP()
exit 0
