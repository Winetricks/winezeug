;
; AutoHotKey Test Script for Microsoft Excel Viewer 2003
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

testname=excelviewer03

#Include helper_functions
#Include init_test

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
DOWNLOAD("http://download.microsoft.com/download/9/e/f/9ef13e5d-2116-40de-ab97-310811f0f3ca/xlviewer.exe", "xlviewer.exe", "b113bf9fbd646d49e584bd526825aee045f9c972")
DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/testfiles/winetest.xls","winetest.xls","0467a3f5367ca95e9004c6fabab3a1b7e49fd526")

; Claims to support /Q, but doesn't work on Wine or Windows XP
Run, xlviewer.exe
ERROR_TEST("Running xlviewer installer had a problem.", "Running xlviewer installer went okay.")
WINDOW_WAIT("Microsoft Office Excel Viewer 2003 Setup", "End-User License Agreement")
Sleep 100 ; I actually had race conditions in this installer, so being extra careful
ControlClick, I &accept the terms in the License Agreement, Microsoft Office Excel Viewer 2003 Setup, End-User License Agreement
Sleep 100
ControlClick, &Next, Microsoft Office Excel Viewer 2003 Setup, End-User License Agreement

WINDOW_WAIT("Microsoft Office Excel Viewer 2003 Setup", "Choose where to install Excel Viewer")
Sleep 100
ControlClick, &Install, Microsoft Office Excel Viewer 2003 Setup, Choose where to install Excel Viewer

WINDOW_WAIT("Microsoft Office Excel Viewer 2003 Setup", "Now Installing Excel Viewer")

WINDOW_WAIT("Microsoft Office Excel Viewer 2003 Setup", "Microsoft Office Excel Viewer 2003 Setup has completed successfully.")
Sleep 100
ControlClick, OK, Microsoft Office Excel Viewer 2003 Setup, Microsoft Office Excel Viewer 2003 Setup has completed successfully.

Sleep 2000

CHECK_DIR("C:\MSOCACHE")

; On windows, it installs in All users, not the current user. Want to check a few other installs before filing a bug
SetWorkingDir, %A_Programs%
ERROR_TEST("Setting work directory gave an error.", "Setting work directory went okay.")
CHECK_FILE("Microsoft Office Excel Viewer 2003.lnk")

SetWorkingDir, %A_ProgramFiles%
ERROR_TEST("Setting work directory gave an error.", "Setting work directory went okay.")
CHECK_DIR("Common Files\SYSTEM")
SHA1("60ee0be034a623ba61ba271f8b17115adddcdad0","Common` Files\Microsoft` Shared\OFFICE11\1033\LCCWIZ.DLL")
SHA1("d7c7d203be08ee3a9bda476a218100710e02a5f9","Common` Files\Microsoft` Shared\OFFICE11\1033\MSOINTL.DLL")
SHA1("75f2c39d58f3f76f968d62217723ae6a9a4bd124","Common` Files\Microsoft` Shared\OFFICE11\MSOICONS.EXE")
SHA1("a80bc181f53ae0172c5354587fac2463e0ece8b5","Common` Files\Microsoft` Shared\OFFICE11\MSO.DLL")
SHA1("170290115fa1dec1b2e6f43c59996d442857db1b","Common` Files\Microsoft` Shared\Source` Engine\OSE.EXE")
SHA1("dc1404aed06d2f966ebef8ee0bf15aef64881072","Microsoft` Office\OFFICE11\GDIPLUS.DLL")
SHA1("807f846262fd7fcf531aaa8165c8ae11084c22c9","Microsoft` Office\OFFICE11\XLVIEW.EXE")
SHA1("5d0a94ee799fd031b630bbcea54885eb32bc57c5","Microsoft` Office\OFFICE11\XLVPRTID.XML")
SHA1("97b787111f54920d039c5660a1b6c53713f1ff91","Microsoft` Office\OFFICE11\1033\XLVINTL.DLL")

SetWorkingDir, %A_ProgramFiles%\Microsoft Office\OFFICE11\
ERROR_TEST("Setting work directory gave an error.", "Setting work directory went okay.")
FileCopy, %APPINSTALL%\winetest.xls, %A_WorkingDir%, 1
ERROR_TEST("Copying winetest.xls had some error.", "Copying winetest.xls went okay.")

Run, XLVIEW.EXE winetest.xls
ERROR_TEST("Running xlviewer had some error.", "Running xlviewer went okay.")

WINDOW_WAIT("Microsoft Excel Viewer - winetest.xls", "winetest.xls")

Sleep 3000 ; Leave it up for a few seconds

CLOSE("Microsoft Excel Viewer - winetest.xls")
ERROR_TEST("Closing Excel Viewer gave an error.", "Closing Excel Viewer went okay.")

Sleep 500

WIN_EXIST_TEST("Microsoft Excel Viewer - winetest.xls")

exit 0
