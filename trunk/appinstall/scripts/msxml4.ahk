;
; AutoHotKey Test Script for MSXML 4
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

testname=msxml4

#Include helper_functions
#Include init_test

; Download MSXML4, silently run the installer, sha1sum installed files, and exit.
; FIXME: How can we verify it works?

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
ERROR_TEST("Downloading sha1sum had an error.", "Downloading sha1sum went okay.")
DOWNLOAD("http://download.microsoft.com/download/e/2/e/e2e92e52-210b-4774-8cd9-3a7a0130141d/msxml4-KB927978-enu.exe", "msxml4-KB927978-enu.exe", "d364f9fe80c3965e79f6f64609fc253dfeb69c25")
ERROR_TEST("Downloading msxml4 had some error.", "Downloading msxml4 went okay.")

Runwait, msxml4-KB927978-enu.exe /q
ERROR_TEST("Installing msxml4 had some error.", "Installing msxml4 went okay.")

Sleep 500

IfNotExist, %A_ProgramFiles%\MSXML 4.0
{
    FileAppend, MSXML 4.0 directory doesn't exist. Test failed.`n, %OUTPUT%
}
Else
{
    FileAppend, MSXML 4.0 directory exists. Test passed.`n, %OUTPUT%
}

; Sha1sum - fc20b297edd27a66d68e399b8acbaef4a1c11d37
IfExist, %A_windir%\Installer\{37477865-A3F1-4772-AD43-AAFC6BCFF99F\icon.exe
{
    FileAppend, icon.exe was installed. Bug 19116 TODO_FIXED.`n, %OUTPUT%
}
Else
{
    FileAppend, icon.exe wasn't installed. Bug 19116 TODO_FAILED.`n, %OUTPUT%
}

Setworkingdir, %A_Windir%
SHA1("e5f81585e4c25fea88b1e06948bf143116d1b279", "system32\msxml4.dll")
SHA1("b360c17666f748e424e1802e79b9c8fc827d754e", "system32\msxml4r.dll")
SHA1("d7e9207fb3fb5053da2dc5a06da3974e7a3018f0", "winsxs\manifests\x86_Microsoft.MSXML2_6bd6b9abf345378f_4.20.9841.0_x-ww_18171213.cat")
SHA1("4c26baf4c1847497d8bead2d0272338e4cbd44bd", "winsxs\manifests\x86_Microsoft.MSXML2_6bd6b9abf345378f_4.20.9841.0_x-ww_18171213.manifest")
SHA1("0943a85da0ff94e014a9f63f89fd14584399ce58", "winsxs\manifests\x86_Microsoft.MSXML2R_6bd6b9abf345378f_4.1.0.0_x-ww_29c3ad6a.cat")
SHA1("bb89a92e5345a922f778ccafa68bed5f7a0e3967", "winsxs\manifests\x86_Microsoft.MSXML2R_6bd6b9abf345378f_4.1.0.0_x-ww_29c3ad6a.manifest")
SHA1("0af1cd619eadca1449e846322867e7b6d102a827", "winsxs\Policies\x86_policy.4.20.Microsoft.MSXML2_6bd6b9abf345378f_x-ww_88e8eab8\4.20.9841.0.cat")
SHA1("b3f47346a1abcaec930d9960c2564ed88af508da", "winsxs\Policies\x86_policy.4.20.Microsoft.MSXML2_6bd6b9abf345378f_x-ww_88e8eab8\4.20.9841.0.policy")
SHA1("e5f81585e4c25fea88b1e06948bf143116d1b279", "winsxs\x86_Microsoft.MSXML2_6bd6b9abf345378f_4.20.9841.0_x-ww_18171213\msxml4.dll")
SHA1("b360c17666f748e424e1802e79b9c8fc827d754e", "winsxs\x86_Microsoft.MSXML2R_6bd6b9abf345378f_4.1.0.0_x-ww_29c3ad6a\msxml4r.dll")

FileAppend, All files sha1sum's matched. Test passed.`n, %OUTPUT%

exit 0