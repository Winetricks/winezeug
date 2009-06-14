;
; AutoHotKey Test Script for Media Player Classic
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

testname=mpc

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

; Download Media Player Classic, unzip it, run it, verify the window exist, and exit.

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/unzip/unzip.exe", "unzip.exe", "ebfd20263e0a448e857967d4f32a2e85b2728923")
DOWNLOAD("http://prdownloads.sourceforge.net/guliverkli/mpc2kxp6490.zip", "mpc2kxp6490.zip", "a9a3a6204a4d99568320da50f18929073b52ee3a")

FileDelete, %APPINSTALL_TEMP%\mpc\*
ERROR_TEST("Removing old temp files failed.", "Removed old temp files.")

Runwait, unzip.exe mpc2kxp6490.zip
ERROR_TEST("Unzipping had some error.", "Unzipping went okay.")
Sleep 500
SHA1("a03c553098112836a9d8973dded1e7c04b68ada6", "mplayerc.exe")

Run, mplayerc.exe
ERROR_TEST("Launching Media Player Classic reported an error.", "Media Player Classic launched fine.")

WINDOW_WAIT("Media Player Classic", "Shader Editor")
Sleep 500 ; Prevent race condition
FORCE_CLOSE("Media Player Classic")
ERROR_TEST("Closing Media Player Classic reported an error.", "Media Player Classic closed fine.")

FileDelete, mplayerc.exe
exit 0