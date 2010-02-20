;
; AutoHotKey Installer Script for MS Visual C++ 2005 Trial
;
; Copyright (C) 2010 Austin English
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

SetControlDelay, -1
WINDOW_WAIT(windowname, windowtext="", wintimeout=12000)
{
    global 
    WinWait, %windowname%, %windowtext%, %wintimeout%
    if ErrorLevel
    {
        FileAppend, Launching %windowname%`, %windowtext% failed. Test failed.`n, *
        exit 1
    }
    IfWinNotActive, %windowname%, %windowtext%
    {
        WinActivate, %windowname%, %windowtext%
    }
}
; Very slow installer, give it a long time...
WINDOW_CLICK_LOOP(windowname, button, windowtext="", loops=10, wintimeout=100000)
{
    global 

    WinWait, %windowname%, %windowtext%, %wintimeout%
    if ErrorLevel
    {
        FileAppend, Launching %windowname%`, %windowtext% failed.`n, *
        exit 1
    }
    IfWinNotActive, %windowname%, %windowtext%
    {
        WinActivate, %windowname%, %windowtext%
    }

    Loop, %loops%
    {
        IfWinExist, %windowname%, %windowtext%
        {
            FileAppend, Trying to click '%button%' again...`n, *
            ControlClick, %button%, %windowname%, %windowtext%
        }
        Else
        {
            FileAppend, '%button%' finally worked.`n, *
            break
        }
        sleep 1000
    }

}

Run, setup.exe
WINDOW_CLICK_LOOP("Microsoft Visual Studio 2005", "&Next >", "Loading completed. Click Next to continue.") /* If unreliable, try button# instead */
WINDOW_WAIT("Microsoft Visual Studio 2005 Setup - Start Page")

; Don't want a WINDOW_CLICK_LOOP, because the window doesn't disappear after clicking
ControlClick, I &accept the terms of the License Agreement, Microsoft Visual Studio 2005 Setup - Start Page

; Try several times to click Next, the button is flaky
    Loop, 15
    {
        ControlClick, Button40, Microsoft Visual Studio 2005 Setup - Start Page
        Sleep 1000
        IfWinNotActive, Microsoft Visual Studio 2005 Setup - Start Page /* Should mean that the button clicked */
        {
            break 2
        }
    }

WINDOW_CLICK_LOOP("Microsoft Visual Studio 2005 Setup", "&OK", "You have chosen to install Visual Studio Trial Edition. This edition allows you to use the product for 180 days.") /* If unreliable, try button# instead */
WINDOW_CLICK_LOOP("Microsoft Visual Studio 2005 Setup - Options Page", "Button11")
WINDOW_CLICK_LOOP("Microsoft Visual Studio 2005 Setup - Finish Page", "&Finish") /* If unreliable, try button# instead */
WINDOW_CLICK_LOOP("Microsoft Visual Studio 2005", "&Restart Now", "You must restart your computer to complete the installation.") /* If unreliable, try button# instead */
