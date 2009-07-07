;
; AutoHotKey Test Script for Respondus Lockdown Browser
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

testname=lockdown

#Include helper_functions
#Include init_test

; Should be http://www.respondus.com/LDB2/LockDownBrowser.php?instid=451214388, but doing so gives inconsistent sha1sum's (custum version for each download?)
; Fortunately, my university has their version available for public download, so let's use that.

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
ERROR_TEST("Downloading sha1sum had an error.", "Downloading sha1sum went okay.")
DOWNLOAD("http://hdc.tamu.edu/files/book/6/425/LockDownSetup_1.0.3.exe", "LockDownSetup_1.0.3.exe", "4f94b13c44324bb795020c09502ec87bfe0106c5")
ERROR_TEST("Downloading Lockdown had some error.", "Downloading Lockdown went okay.")

Run, LockDownSetup_1.0.3.exe
ERROR_TEST("Launching Lockdown had some error.", "Launching Lockdown went okay.")

WINDOW_WAIT("EasySFX(tm) -", "Created with the Registered Version of PKSFX® for Windows")
ControlClick, Button1, EasySFX(tm) -, Created with the Registered Version of PKSFX® for Windows

WINDOW_WAIT("EasySFX(tm) -", "Extraction completed.")
; Bug 18934
ControlClick, &Yes, EasySFX(tm) -, Extraction completed.

WINDOW_WAIT("Respondus LockDown Browser - InstallShield Wizard", "The InstallShield Wizard will install Respondus LockDown Browser on your computer")
ControlClick, Button1, Respondus LockDown Browser - InstallShield Wizard, The InstallShield Wizard will install Respondus LockDown Browser on your computer

WINDOW_WAIT("Respondus LockDown Browser - InstallShield Wizard", "Please read the following license agreement carefully.")
ControlClick, Button5, Respondus LockDown Browser - InstallShield Wizard, Please read the following license agreement carefully.
ControlClick, Button2, Respondus LockDown Browser - InstallShield Wizard, Please read the following license agreement carefully.

WINDOW_WAIT("Respondus LockDown Browser - InstallShield Wizard", "Install Respondus LockDown Browser to:")
ControlClick, Button1, Respondus LockDown Browser - InstallShield Wizard, Install Respondus LockDown Browser to:

WINDOW_WAIT("Respondus LockDown Browser - InstallShield Wizard", "Click Install to begin the installation.")
ControlClick, Button1, Respondus LockDown Browser - InstallShield Wizard, Click Install to begin the installation.

WINDOW_WAIT("Respondus LockDown Browser - InstallShield Wizard", "Click Finish to exit the wizard")
ControlClick, Button4, Respondus LockDown Browser - InstallShield Wizard, Click Finish to exit the wizard

; It installs a couple files in system32
Setworkingdir, %A_WinDir%\system32
SHA1("97d1590e893eaef2c03b786174ed32d51e3b646f", "fpimage.dll")
SHA1("6c6e962c42ecb0cecdad7f5d340b78f801e9f335", "FPSPR70.ocx")

Setworkingdir, %ProgramFiles%\Respondus LockDown Browser
SHA1("11e9d4211cbefcf195adcfef8b23bb32a752f909", "LDBD.exe")
SHA1("97750c2dd1b8f7e1e103d11f9003df6a58810ca5", "LockDown.exe")
SHA1("2ba7be0ab0fcdc93f7e2b9ec4d338f25151f5aa2", "RPUPDATE.exe")
SHA1("1d4cdeba266eb8d2fd050332ae6433c5bf6f11c4", "TaskKeyHook.dll")
SHA1("d5502a1d00787d68f548ddeebbde1eca5e2b38ca", "msvcr71.dll")

; Store the process id so we can terminate it later
Run, Lockdown.exe, , ,lockpid
ERROR_TEST("Running Lockdown reported an error.", "Lockdown launched fine.")

    WinWait, Respondus LockDown Browser, Shell Embedding, 5
    if ErrorLevel
    {
        FileAppend, Couldn't detect Respondus LockDown Browser. You're likely on windows. If not`, bug 19083 TODO_FIXED.`n, %OUTPUT%
    }
    else
    {
        FileAppend, Respondus LockDown Browser detected. Bug 19083 TODO_FAILED.`n, %OUTPUT%
    }

; The Lockdown browser does just that...locks things down, hard. Detecting its windows, etc., is broken. Sending ALT+F4, broken.
; So, since it wants to play tough, let's do the same, and terminate it's pid. Yes, this is dirty. Very dirty. But since they won't
; play nice and let us close with ALT+F4, we don't have much choice...clicking the mouse in the 'just right' position is even harder/impossible.

; On Windows, this will break the start bar. I'm not sure how to work around that.
; But since we don't test on Windows often, it's a non-issue.
    Process, Close, %lockpid%
    Sleep 500
    WIN_EXIST_TEST("Respondus LockDown Browser")

exit 0
