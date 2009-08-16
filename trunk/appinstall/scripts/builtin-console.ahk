;
; AutoHotKey Test Script - Builtin console programs
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

; This script is a bit of a special case...it tests all of wine's built in programs.
; Some of these don't follow their window's counterparts perfectly, or at all, so
; 'bug for bug' compatability is not extremely important here. What _IS_ important,
; is that what works in wine now keeps working in the future, and to catch any TODO_FIXED bugs.

#Include helper_functions
#Include init_test

; Fixme: hh/rpcss (never exit), winevdm/start (returns 1 for license), services (how to call?), termsv

consoleprogs = icinfo,lodctr,msiexec /h,net help,regsvr32,rundll32,secedit,wineconsole,winedbg --help,winepath,xcopy /?
Loop, parse, consoleprogs, `,
{
    Runwait, %A_LoopField%, , UseErrorLevel
    If %A_LastError% != 0
    {
        FileAppend, Running %A_LoopField% failed. Test failed.`n, %OUTPUT%
    }
    Else
    {
        FileAppend, Running %A_LoopField% succeeded. Test passed.`n, %OUTPUT%
    }
}

TEST_COMPLETED()

exit 0