;
; AutoHotKey Test Script for Nestopia
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

testname=nestopia

#Include helper_functions
#Include init_test

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/unzip/unzip.exe", "unzip.exe", "ebfd20263e0a448e857967d4f32a2e85b2728923")
DOWNLOAD("http://downloads.sourceforge.net/nestopia/Nestopia140bin.zip", "Nestopia140bin.zip", "2e0a89ca006a4af1b3cd708e796cb55b9a45d21e")

FileRemoveDir, %APPINSTALL_TEMP%\nestopia140, 1
ERROR_TEST("Removing old temp files failed.", "Removed old temp files.")

Run, unzip.exe -d %APPINSTALL_TEMP%\nestopia140 Nestopia140bin.zip
ERROR_TEST("Unzipping had some error.", "Unzipping went okay.")

; Sleep for a second to make sure a race condition in the unzip process doesn't break the test
Sleep 500

SetWorkingDir, %APPINSTALL_TEMP%\nestopia140
ERROR_TEST("Setting work directory failed.", "Setting work directory went fine.")

SHA1("8779ee03e1704c313e20c07b7a9192c32f7f7f85", "language\english.nlg")
SHA1("e571a428bef389910cf3f10191b44700b8855d5f", "nestopia.exe")
SHA1("8833d234e90dee382be5199bd75e1a1131e0f81c", "changelog.txt")
SHA1("08db7a053b9b3251c4575c534250134e55110fd9", "readme.html")
SHA1("bdd64f474d82fde4bed5dd424e716f1e07bbd3bf", "schemadb.xsd")
SHA1("3376c94bb779f43b0fc62eaabd600187ed9538e8", "schemaromset.xsd")
SHA1("85e61fb599009b49714187ced07710aef772bf67", "copying.txt")
SHA1("5b189298039b67df653c62db5d5c490472ccbef7", "unrar.dll")
SHA1("ad761c61e7c9b6bdfc889912c178b649672c9c54", "7zxa.dll")
SHA1("f0e3790f0a867f656ee614dc4e4a216515276cba", "kailleraclient.dll")

Run, nestopia.exe

WINDOW_WAIT("Nestopia")
PostMessage, 0x112, 0xF060,,, Nestopia

WINDOW_WAIT("Exit Nestopia", "Are you sure")
; Bug 18934
ControlClick, &Yes, Exit Nestopia, Are you sure

Sleep 500

IfWinExist, Nestopia
{
    FileAppend, Nestopia didn't exit for some reason. Test failed.`n, %OUTPUT%
}
IfWinNotExist, Nestopia
{
    FileAppend, Nestopia exited successfully. Test passed.`n, %OUTPUT%
}

CLEANUP()
exit 0
