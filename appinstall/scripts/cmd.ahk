;
; AutoHotKey Test Script - Command tests
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

; For a ton of hidden features, check out:
; http://stackoverflow.com/questions/245395/underused-features-of-windows-batch-files#246691
; Ideally, there should be tests for all of them...

; Test the output from a command. Capturing stdout on windows is a bit difficult,
; e.g., you can only do so (AFAICT) in AutoHotKey by piping it to a file.
; If there's another way, please, for the love of the FSM, please let me know.
test_output(commandtotest, expectedresult)
{
    global
    TEMPFILE=%APPINSTALL_TEMP%\result.txt   
    
    FileDelete, %TEMPFILE%

    Runwait, %comspec% /c %commandtotest% > %TEMPFILE%
    FileRead, result, %TEMPFILE%
    FileDelete, %TEMPFILE%

    If (result != expectedresult)
    {
        FileAppend, expected "%expectedresult%" got "%result%". TEST FAILED.`n, %OUTPUT%
    }
    else
    {
        FileAppend, expected "%expectedresult%" got "%result%". TEST PASSED.`n, %OUTPUT%
    }
}

todo_test_output(commandtotest, expectedresult, bug)
{
    global
    TEMPFILE=%APPINSTALL_TEMP%\result.txt   
    
    FileDelete, %TEMPFILE%

    Runwait, %comspec% /c %commandtotest% > %TEMPFILE%
    FileRead, result, %TEMPFILE%
    FileDelete, %TEMPFILE%

    If (result = expectedresult)
    {
        FileAppend, expected "%expectedresult%" got "%result%". Check bug %bug%. TODO_FIXED.`n, %OUTPUT%
    }
    else
    {
        FileAppend, expected "%expectedresult%" got "%result%". Bug %bug% TODO_FAILED.`n, %OUTPUT%
    }
}

; The command must be enclosed in quotes, which isn't ideal, since we want to test quote behavior.
; Using double-double quotes works around it, e.g., '"echo ""foo"""' which sends the command 'echo "foo"'

; Notice that you must account for the newlines the echo produces. It also adds a space at the end.
test_output("echo foo", "foo `r`n")

; Single quotes are ignored:
test_output("echo 'foo'", "'foo' `r`n")

; Adding '@' at the beginning has no effect:
test_output("@echo foo", "foo `r`n")

; I don't think Wine should match this exactly. It's mostly there to test a more complex comparison...
todo_test_output("echo /?", "Displays messages, or turns command-echoing on or off.`r`n`r`n  ECHO [ON | OFF]`r`n  ECHO [message]`r`n`r`nType ECHO without parameters to display the current echo setting.`r`n", "21129")
; Escaping it works fine though:
todo_test_output("echo ""/?""", """/?"" `r`n","20161")

; Using 'echo.' without a space between gives a blank line:
todo_test_output("echo.", " `r`n", "21130")

test_output("echo .", ". `r`n")

; Echo on/off turns echo on or off, and shouldn't give _any_ output, not even a newline/space:
todo_test_output("echo on", "", "21132")
todo_test_output("echo off", "", "21132")

; But enclosing it in single quotes makes it okay
test_output("echo 'on'", "'on' `r`n")
test_output("echo 'off'", "'off' `r`n")

todo_test_output("echo ""on""", """on"" `r`n","20161")
todo_test_output("echo ""off""", """off"" `r`n","20161")

; Some characters must be escaped. On Windows, the error is NOT sent to stdout/stderr,
; so, e.g., 'echo |' shows 'The syntax of the error is incorrect.', but doing
; 'echo | > foo.txt' still shows that error, and foo.txt is never created:
test_output("echo |", "")
todo_test_output("echo ^", "Echo is on.`r`n","18346")
todo_test_output("echo ^^", "^ `r`n","18346")
todo_test_output("echo ^|", "| `r`n","18346")
todo_test_output("echo ^>", "> `r`n","18346")
todo_test_output("echo ^<", "< `r`n","18346")

; This returns 'Echo is on.' to stdout, but if piped, gives an empty file
test_output("echo &", "")
todo_test_output("echo ^&", "& `r`n","18346")
todo_test_output("echo ""&""", """&"" `r`n","21131")

; The redirect ('<' and '>') characters have similar behavior, but since the only
; way to get the the output is to redirect it, that can't be tested here.
; test_output("echo >", "")
; test_output("echo <", "^ `r`n")

; Surprisingly, these don't need to be escaped:
test_output("echo \", "\ `r`n")
test_output("echo \\", "\\ `r`n")
test_output("echo /", "/ `r`n")
test_output("echo //", "// `r`n")
test_output("echo *", "* `r`n")
test_output("echo **", "** `r`n")

; Now for some comparison statements:
; test_output("IF 0 == 0 echo foo1", "foo1 `r`n") - fails on wine, but works manually...
todo_test_output("IF 0 EQU 0 echo foo2", "foo2 `r`n", "21046")
todo_test_output("IF 0 NEQ 1 echo foo3", "foo3 `r`n", "21046")
todo_test_output("IF 0 LSS 1 echo foo4", "foo4 `r`n", "21046")
todo_test_output("IF 0 LEQ 1 echo foo5", "foo5 `r`n", "21046")
todo_test_output("IF 0 GTR -1 echo foo6", "foo6 `r`n", "21046")
todo_test_output("IF 0 GEQ -1 echo foo7", "foo7 `r`n", "21046")

todo_test_output("IF NOT foo==bar echo foo8", "foo8 `r`n", "21046")

; Using /I performs a case insensitive match:
test_output("IF bar==BAR echo bar", "")
todo_test_output("IF /i bar==BAR echo bar1", "bar1 `r`n", "21145")

; Test defined variables:
todo_test_output("IF defined windir echo bar2", "bar2 `r`n", "18712")

Runwait, %comspec% /c set foo=  ; Unset foo, just in case it was somehow set
todo_test_output("If NOT defined foo echo bar3", "bar3 `r`n", "18712")

/* These are failing on Wine, but when run manually, it works. Need to investigate further.
; IF exist:
IfExist, a.txt
    FileDelete, a.txt
Runwait, %comspec% /c echo foobar > a.txt
test_output("IF EXIST a.txt echo bar4", "bar4 `r`n")
FileDelete, a.txt
test_output("If NOT EXIST a.txt echo bar5", "bar5 `r`n")

; Parentheses tests. Can't use the test_output()/todo_test_output functions because
; of the nested parentheses.
commandtotest="if 0==0 (echo a)"
expectedresult=a`r`n
TEMPFILE=%APPINSTALL_TEMP%\result.txt
FileDelete, %TEMPFILE%
Runwait, %comspec% /c %commandtotest% > %TEMPFILE%
FileRead, result, %TEMPFILE%
FileDelete, %TEMPFILE%
If (result != expectedresult)
        FileAppend, expected "%expectedresult%" got "%result%". TEST FAILED.`n, %OUTPUT%
*/

commandtotest="if 0==1 (echo a) else echo b"
expectedresult=b `r`n
TEMPFILE=%APPINSTALL_TEMP%\result.txt   
FileDelete, %TEMPFILE%
Runwait, %comspec% /c %commandtotest% > %TEMPFILE%
FileRead, result, %TEMPFILE%
FileDelete, %TEMPFILE%
If (result != expectedresult)
    {
        FileAppend, expected "%expectedresult%" got "%result%". Bug 21142 regressed. TEST FAILED.`n, %OUTPUT%
    }
else
    {
        FileAppend, expected "%expectedresult%" got "%result%". TEST PASSED.`n, %OUTPUT%
    }


TEST_COMPLETED()

exit 0
