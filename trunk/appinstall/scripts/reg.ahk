;
; AutoHotKey Test Script - reg.exe
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

#Include helper_functions
#Include init_test

; These return 0. Should pass in Windows and Wine:
regfunc0 = reg.exe,reg.exe /h,reg.exe /?,reg.exe query /?,reg.exe query /h,reg.exe add /?,reg.exe add /h,reg.exe delete /?,reg.exe delete /h
Loop, parse, regfunc0, `,
{
    Runwait, %A_LoopField%
    if ErrorLevel
    {
        FileAppend, Running %A_LoopField% failed. Test failed.`n, %OUTPUT%
    }
    else
    {
        FileAppend, Running %A_LoopField% succeeded. Test passed.`n, %OUTPUT%
    }
}

; These return an error: Should pass on Windows and Wine:
regfunc1 = reg.exe query,reg.exe add,reg.exe delete
Loop, parse, regfunc1, `,
{
    Runwait, %A_LoopField%
    if ErrorLevel
    {
        FileAppend, Running %A_LoopField% returned an error. Test passed.`n, %OUTPUT%
    }
    else
    {
        FileAppend, Running %A_LoopField% worked? Test failed.`n, %OUTPUT%
    }
}

; These return 0. Passes in Windows, Wine bug 19533.
; Yes, the line is long...Breaking it out over multiple lines and continuing it with a ',' should work, but was buggy for me.
todofunc0 = reg.exe copy /?,reg.exe copy /h,reg.exe save /?,reg.exe save /h,reg.exe restore /?,reg.exe restore /h,reg.exe load /?,reg.exe load /h,reg.exe unload /?,reg.exe unload /h,reg.exe compare /?,reg.exe compare /h,reg.exe export /?,reg.exe export /h
Loop, parse, todofunc0, `,
{
    Runwait, %A_LoopField%
    if ErrorLevel
    {
        FileAppend, Running %A_LoopField% failed. Bug 19533 TODO_FAILED.`n, %OUTPUT%
    }
    else
    {
        FileAppend, Running %A_LoopField% succeeded. Bug 19533 TODO_FIXED.`n, %OUTPUT%
    }
}

; These return an error. Passes in Windows. They fail on wine as well, since it returns an error for 'invalid' options.
todofunc1 = reg.exe copy,reg.exe save,reg.exe restore,reg.exe load,reg.exe unload,reg.exe compare,reg.exe export
Loop, parse, todofunc1, `,
{
    Runwait, %A_LoopField%
    if ErrorLevel = 1
    {
        FileAppend, Running %A_LoopField% returned an error. Test passed.`n, %OUTPUT%
    }
    else
    {
        FileAppend, Running %A_LoopField% worked? Test failed.`n, %OUTPUT%
    }
}

; Make sure invalid operations fail
Runwait, reg.exe foobar
if ErrorLevel
    {
        FileAppend, Running reg.exe foobar returned an error. Test passed.`n, %OUTPUT%
    }
    else
    {
        FileAppend, Running reg.exe foobar worked? Test failed.`n, %OUTPUT%
    }

; FIXME: add tests for actually importing/exporting/comparing registry keys, then verify the change(s).

TEST_COMPLETED()

exit 0