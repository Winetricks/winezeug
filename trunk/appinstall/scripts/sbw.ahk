;
; AutoHotKey Test Script for Savings Bond Wizard
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

testname=sbw

; Don't mess with these includes. 'helper_functions' includes the helper functions used by the tests,
; and 'init_test' sets up the folders, removes old temp files, etc.
#Include helper_functions
#Include init_test

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
; Update the below info for your program. Be sure to leave the quotes!
DOWNLOAD("http://www.treasurydirect.gov/indiv/tools/sbwsetup.exe", "sbwsetup.exe", "119abc5b5a2738357d661f26285f16b18d1edc75")

Run, sbwsetup.exe
ERROR_TEST("Launching Savings Bond Wizard setup had some error.", "Launching Savings Bond Wizard setup went okay.")

WINDOW_WAIT("Welcome", "Welcome to the Savings Bond Wizard Setup program!")
ControlClick, Button1, Welcome, Welcome to the Savings Bond Wizard Setup program!

WINDOW_WAIT("Product Disclaimer", "Please read the following disclaimer.")
ControlClick, Button4, Product Disclaimer, Please read the following disclaimer.

WINDOW_WAIT("Choose Destination Location", "Setup will install Savings Bond Wizard in the following directory.")
ControlClick, Button1, Choose Destination Location, Setup will install Savings Bond Wizard in the following directory.

WINDOW_WAIT("Ready To Install", "Setup now has enough information to start installing Savings Bond Wizard.")
ControlClick, Button1, Ready To Install, Setup now has enough information to start installing Savings Bond Wizard.

WINDOW_WAIT("Finished", "Setup is complete and Savings Bond Wizard is now installed!")
ControlClick, Button1, Finished, Setup is complete and Savings Bond Wizard is now installed!

Setworkingdir, %a_windir%
SHA1("a707632c8abdf6116c2afe425439c48671fcdf35", "unvise32.exe")

Setworkingdir, %programfiles%\Savings Bond Wizard
SHA1("ea6c886f83d92d22d57488402854f16ca5a9e0f9", "about.exe")
SHA1("53969c0fa94cfce455d91694df6b96b25864466e", "crv_e.txt")
SHA1("665b89577f610860572d21b39ee0b12d9c031f30", "crv_ee.txt")
SHA1("7ec67372d3efb4aa532487ad7ffae663002d9b24", "crv_h.txt")
SHA1("7ec67372d3efb4aa532487ad7ffae663002d9b24", "crv_hh.txt")
SHA1("01afb013a29e0349f18209cb03167bd152bd3882", "crv_i.txt")
SHA1("e9410bc3577f43bf65d0f40eae3d058611c9a380", "crv_periods.txt")
SHA1("7b22522e6baafbf40cee50dcb5a4fb65eda2495b", "crv_sn.txt")
SHA1("6f072609b9bf59b64e0e65cd00b4227e205032a9", "SBWizard.exe")
SHA1("958cae199a00af3f151aa31e882301a2c3c426f7", "SBWizHelp.chm")
SHA1("b1f00abfe787f6495b24420aa39e4a09e2d7780a", "splash.exe")

Run, SBWizard.exe
ERROR_TEST("Running Savings Bond Wizard reported an error.", "Savings Bond Wizard launched fine.")

Window_wait("Savings Bond Wizard - Untitled 1", "Deferred Interest")
ERROR_TEST("Savings Bond Wizard window never appeared.", "Savings Bond Wizard window appeared fine.")

; It has a splash screen that takes a few seconds to go away. Giving it a couple extra to be safe.
Sleep 5000

FORCE_CLOSE("Savings Bond Wizard - Untitled 1")
;WinKill, Savings Bond Wizard - Untitled 1, Deferred Interest
ERROR_TEST("Exiting Savings Bond Wizard gave an error.", "Savings Bond Wizard claimed to exit fine.")

Sleep 500

IfWinExist, Savings Bond Wizard - Untitled 1
{
    FileAppend, Savings Bond Wizard didn't exit for some reason. Test failed.`n, %OUTPUT%
}
IfWinNotExist, Savings Bond Wizard - Untitled 1
{
FileAppend, Savings Bond Wizard exited successfully. Test passed.`n, %OUTPUT%
}

; Exit and report success
exit 0