;
; AutoHotKey Test Script for McAfee Avert Stinger
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

testname=stinger

#Include helper_functions
#Include init_test

; Download Stinger, run it, verify the window exists, and exit.

DOWNLOAD("http://download.nai.com/products/mcafee-avert/stinger1001546.exe", "stinger.exe", "998a745f3258a432a5bc2047825995aa9e6cb7d6")

Run, stinger.exe

Window_wait("Stinger", "Directories to scan:", 5)

ERROR_TEST("Stinger window never appeared.", "Stinger launched fine.")

FORCE_CLOSE(Stinger)

ERROR_TEST("Exiting Stinger gave an error.", "Stinger claimed to exit fine.")

; Prevent race condition
Sleep 500

WIN_EXIST_TEST("Stinger")

FileDelete, Stinger*opt

CLEANUP()
exit 0
