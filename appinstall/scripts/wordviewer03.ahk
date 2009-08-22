;
; AutoHotKey Test Script for Microsoft Word Viewer 2003
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
#Include init_test

DOWNLOAD("http://download.microsoft.com/download/6/a/6/6a689355-b155-4fa7-ad8a-dfe150fe7ac6/wordview_en-us.exe", "wordview_en-us.exe", "e6dfdc8a1545d45ef5840ba513a5c4036bf154bc")
DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/testfiles/winetest.doc","winetest.doc","ec3feb84f2ac6e52e616c17fbd18fde5f2f39f33")

Run, wordview_en-us.exe /q
ERROR_TEST("Installing wordviewer had a problem.", "Installing wordviewer went okay.")

Sleep 2000

SetWorkingDir, %A_Programs%
ERROR_TEST("Setting work directory gave an error.", "Setting work directory went okay.")
CHECK_FILE("Microsoft Office Word Viewer 2003.lnk")

SetWorkingDir, %A_AppData%\Microsoft\Installer\{90850409-6000-11D3-8CFE-0150048383C9}
ERROR_TEST("Setting work directory gave an error.", "Setting work directory went okay.")
SHA1("a04d93ff282ca7dd1ab449b52a747cce9f35f3f3","misc.exe")
SHA1("efde746e0d8af423d067babba4764892a07909de","wrdvicon.exe")

SetWorkingDir, %A_ProgramFiles%
ERROR_TEST("Setting work directory gave an error.", "Setting work directory went okay.")
TODO_SHA1("60ee0be034a623ba61ba271f8b17115adddcdad0", "92ea0d6e0b0e7985b068d6f49f63b12f41b89b3f","Common` Files\Microsoft` Shared\OFFICE11\1033\LCCWIZ.DLL")
TODO_SHA1("a71b9a807dbbc58d718fe7f6de6fa75021b04bd0","4a67552dff886ded8462f7db0d044a12aef52f32","Microsoft` Office\OFFICE11\GDIPLUS.DLL")
SHA1("f86cfea74acbcd8a9500ee01ed54668c269bb352","Common` Files\Microsoft` Shared\OFFICE11\1033\MSOINTL.DLL")
SHA1("fdbb79fbddcade20159ffc41d950339403ceead4","Common` Files\Microsoft` Shared\OFFICE11\1033\MSXML5R.DLL")
SHA1("fbdde3450180a393890108be2734cf285b4e04e8","Common` Files\Microsoft` Shared\OFFICE11\MSO.DLL")
SHA1("75f2c39d58f3f76f968d62217723ae6a9a4bd124","Common` Files\Microsoft` Shared\OFFICE11\MSOICONS.EXE")
SHA1("be9a1776ce3c08934be2e918b558defa10ba6bae","Common` Files\Microsoft` Shared\OFFICE11\MSXML5.DLL")
SHA1("6812cae360d1db8865ef5aeeef73811822b4b7aa","Common` Files\Microsoft` Shared\OFFICE11\RICHED20.DLL")
SHA1("5dc1cdfd43631a43498cf39399cbb10f4d767dc8","Common` Files\Microsoft` Shared\OFFICE11\UCS20.DLL")
SHA1("256eccd718c0d8c8a15bea78ad464e62491afff7","Common` Files\Microsoft` Shared\OFFICE11\USP10.DLL")
SHA1("170290115fa1dec1b2e6f43c59996d442857db1b","Common` Files\Microsoft` Shared\Source` Engine\OSE.EXE")
SHA1("619e940fa2e30ade774329b52c6ac2f47dd1dc77","Microsoft` Office\OFFICE11\1033\WWINTLV.DLL")
SHA1("89eaad8bb40ae2a539feaab494e710d22dd01f03","Microsoft` Office\OFFICE11\BIDI32.DLL")
SHA1("93413e3e6203b0f78e436e184318b199cb9b2e71","Microsoft` Office\OFFICE11\INTLDATE.DLL")
SHA1("f12137e29e1a5c6c7cbcea7706f51089829a4ca9","Microsoft` Office\OFFICE11\MSOHEV.DLL")
SHA1("289c2eee9b5bcf7f55c699cfb2bb3ed4baad581f","Microsoft` Office\OFFICE11\MSOHTMED.EXE")
SHA1("9e498f4adf68be28576070a5ea15b785bed0e7f0","Microsoft` Office\OFFICE11\SAEXT.DLL")
SHA1("2eea49ad6c9c1144882e76e51c9245e5647ced54","Microsoft` Office\OFFICE11\SEQCHK10.DLL")
SHA1("ec9c3b0baeebd75018679870e7976453adab516a","Microsoft` Office\OFFICE11\UCSCRIBE.DLL")
SHA1("ed1aa889226eb0923f2a7e33a26c40fec8e63618","Microsoft` Office\OFFICE11\WDVPRTID.XML")
SHA1("0012c9e122d363663d2f00c388e9de04d77ff738","Microsoft` Office\OFFICE11\WORDVIEW.EXE")
SHA1("e7c56f4ce8f548e3f45952f44f14063e3e18b15f","Microsoft` Office\OFFICE11\XML2WORD.XSL")
SHA1("0aa57af257765415491b8b0a5c39498c1c2e1eab","MSECache\wordview\Catalog\files12.cat")
SHA1("af5c2d14d7860eeb0997e73aa9085553c231f582","MSECache\wordview\Updates\PREWDVIEWSP3.msp")
SHA1("ac29ef3f8682a112abf097c91c2eaa86293f2c2d","MSECache\wordview\Updates\WDVIEWSP3.msp")
SHA1("315948cede603b272d90be236c2f54409858cd19","MSECache\wordview\wdviewer.cab")
SHA1("b438fae7012101b251b4a2d192d8eec7efa5d943","MSECache\wordview\wordview.msi")

SetWorkingDir, %A_ProgramFiles%\Microsoft Office\OFFICE11
ERROR_TEST("Setting work directory gave an error.", "Setting work directory went okay.")

FileCopy, %APPINSTALL%\winetest.doc, %A_WorkingDir%, 1
ERROR_TEST("Copying winetest.doc had some error.", "Copying winetest.doc went okay.")

Run, WORDVIEW.exe winetest.doc
ERROR_TEST("Running wordviewer had some error.", "Running wordviewer went okay.")

WINDOW_WAIT("winetest.doc - Microsoft Word Viewer", "MsoDockTop")
Sleep 3000 ; Let the window show for a moment before closing.
CLOSE("winetest.doc - Microsoft Word Viewer")
ERROR_TEST("Closing winetest.doc had some error.", "Closing winetest.doc went okay.")
Sleep 500

WIN_EXIST_TEST("winetest.doc - Microsoft Word Viewer")

TEST_COMPLETED()

exit 0
