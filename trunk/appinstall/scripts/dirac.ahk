;
; AutoHotKey Test Script for Dirac 0.8 Video Codec
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

; Download Dirac, install it, sha1sum installed files, and exit.

DOWNLOAD("http://codecpack.nl/dirac_dsfilter_080.exe", "dirac_dsfilter_080.exe", "aacfcddf6b2636de5f0a50422ba9155e395318af")

Runwait, dirac_dsfilter_080.exe /silent
ERROR_TEST("Running dirac had an error.", "Running dirac went fine.")

Sleep 500
SetWorkingDir, %A_ProgramFiles%\Dirac
SHA1("15d20b6f9b10b1b36386abea5f06c590ab57302f", "DiracDecoder.dll")
SHA1("3a772f932ddceba5cddd93c3139606ad613449b9", "DiracSplitter.ax")
SHA1("6445e123a684448ae7a48dddd9c4f1d30faf915b", "unins000.exe")

FileAppend, All files sha1sum's matched. Test passed.`n, %OUTPUT%

exit 0
