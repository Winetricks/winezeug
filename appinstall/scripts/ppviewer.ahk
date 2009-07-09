;
; AutoHotKey Test Script for Microsoft PowerPoint Viewer
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

testname=ppviewer

#Include helper_functions
#Include init_test

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
DOWNLOAD("http://download.microsoft.com/download/a/1/a/a1adc39b-9827-4c7a-890b-91396aed2b86/ppviewer.exe", "ppviewer.exe", "4d13ca85d1d366167b6247ac7340b7736b1bff87")
DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/testfiles/winetest.ppt","winetest.ppt","fe41eeb108e7255f94b91cb02d6f5b1285740bf3")

Run, ppviewer.exe /q
ERROR_TEST("Installing ppviewer had a problem.", "Installing ppviewer went okay.")

TODO_WINDOW_WAIT(Microsoft Office PowerPoint Viewer 2003, 19170, Microsoft Office PowerPoint Viewer 2003 Setup completed successfully, 60)

Sleep 2000

; Need to verify on windows.
; CHECK_FILE("%A_WINDIR%\Installer\*.msi")

; On Wine, this installs to the wrong place. So, let's test for it in both places, and if it's present, SHA1SUM it. Else, failure.
;SetWorkingDir, %A_AppData%\Microsoft\Installer\{90AF0409-6000-11D3-8CFE-0150048383C9}
IfExist %A_WINDIR%\Installer\{90AF0409-6000-11D3-8CFE-0150048383C9}\ppvwicon.exe
{
    SetWorkingDir, %A_WINDIR%\Installer\{90AF0409-6000-11D3-8CFE-0150048383C9}
    SHA1("d3d868146e59ef956922fb11a3ceb94c0991da1b","ppvwicon.exe")
    FileAppend, ppvwicon.exe found in %A_WINDIR%\Installer. Bug 19172 TODO_FIXED.`n, %OUTPUT%
}
Else ifexist %A_AppData%\Microsoft\Installer\{90AF0409-6000-11D3-8CFE-0150048383C9}\ppvwicon.exe
{
    SetWorkingDir, %A_AppData%\Microsoft\Installer\{90AF0409-6000-11D3-8CFE-0150048383C9}
    SHA1("d3d868146e59ef956922fb11a3ceb94c0991da1b","ppvwicon.exe")
    FileAppend, ppvwicon.exe found in %A_AppData%\Microsoft\Installer. Bug 19172 TODO_FAILED.`n, %OUTPUT%
}
Else
{
    FileAppend, ppvwicon.exe not found in either location. Test failed.`n, %OUTPUT%
}

SetWorkingDir, %A_ProgramFiles%\Microsoft Office\PowerPoint Viewer
SHA1("d7dc16818cd1d808017e0507366b50eb7560a47f","GDIPLUS.DLL")
SHA1("182da2e0e2c2b2049be976ed66492f9313e75586","INTLDATE.DLL")
SHA1("cd0f9c2e77f9ccbd9dc95fa15b5523c0a5690d4a","PPTVIEW.EXE")
SHA1("932f9366e6d6d19efc299f7cc88b4c787621d2b9","PPVWINTL.DLL")
SHA1("5ef8fd06f5f3c5eb64d12d832b1d2677083aa030","PVREADME.HTM")
SHA1("531d45e4b4626dc98585e8843a2aecda47c28f30","SAEXT.DLL")
SHA1("0976db1b5b9aa69e77fa25c35c8189e3ef851ffc","UNICOWS.DLL")

FileCopy, %APPINSTALL%\winetest.ppt, %A_WorkingDir%, 1
ERROR_TEST("Copying winetest.ppt had some error.", "Copying winetest.ppt went okay.")

Run, PPTVIEW.exe winetest.ppt
ERROR_TEST("Running ppviewer had some error.", "Running ppviewer went okay.")

WINDOW_WAIT("Microsoft Office PowerPoint Viewer", "&Print License")
ControlClick, Button1, Microsoft Office PowerPoint Viewer

WINDOW_WAIT("PowerPoint Viewer Slide Show - [winetest.ppt]")
; Need to click # of slides+1
ControlClick, paneClassDC1, PowerPoint Viewer Slide Show - [winetest.ppt]
ControlClick, paneClassDC1, PowerPoint Viewer Slide Show - [winetest.ppt]

Sleep 500

WIN_EXIST_TEST("PowerPoint Viewer Slide Show - [winetest.ppt]")

exit 0
