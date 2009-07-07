;
; AutoHotKey Test Script for AutoHotkey
; Brought to you by the Redundancy Department of Redundancy
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

testname=ahk

#Include helper_functions
#Include init_test

; Download ahk, silently run the installer, sha1sum installed files, run it, verify the window exists, and exit.

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
ERROR_TEST("Downloading sha1sum had an error.", "Downloading sha1sum went okay.")
DOWNLOAD("http://www.autohotkey.net/programs/AutoHotkey104803_Install.exe", "AutoHotkey_Install.exe", "5cf0f16e9aa2f2e96a3b08e0d938602aff39a33e")
ERROR_TEST("Downloading AHK had some error.", "Downloading AHK went okay.")

Runwait, AutoHotkey_Install.exe /S
ERROR_TEST("Installing AHK had some error.", "Installing AHK went okay.")

Setworkingdir, %windir%
SHA1("238c8aebc479a92a1c043f44d2ee363b0dce66ce","ShellNew\Template.ahk")

Setworkingdir, %ProgramFiles%\AutoHotKey
SHA1("80a26d11df3b223fdfab2c5e667a7d9e4a1f4126","AutoScriptWriter\ASWHook.dll")
SHA1("cf3480ea6174e1201f09585187bbcab0d4aa1a9b","AutoScriptWriter\AutoScriptWriter.exe")
SHA1("ed293ecb1b9fc5a17340ce85598429b235d4ec07","Compiler\Ahk2Exe.exe")
SHA1("571c0512e08a9565de34752a60885bb6030d4155","Compiler\AutoHotkeySC.bin")
SHA1("c05086f03601d0dc41b1634553acd8a32394df9d","Compiler\README.txt")
SHA1("11520e7042a4950674179f965030daa2e27705ee","Compiler\upx.exe")
SHA1("a9bc3fa4f24dcf6899a28a76faec7781afaabf33","Extras\Editors\ConTEXT\Run` this` to` install` syntax` highlighting` for` ConTEXT.ahk")
SHA1("f60f8877130127217fda05e364ace47d4e067bb5","Extras\Editors\EditPlus\AutoHotkey.ctl")
SHA1("b298ff747bb3c1065b88fc9381e9444ee72fe68f","Extras\Editors\EditPlus\AutoHotkey.stx")
SHA1("899800bef0f946e647c337c1d2281dab3ca955c2","Extras\Editors\EditPlus\Run` this` to` install` syntax` and` cliptext` files` for` EditPlus.ahk")
SHA1("cbe21f201cf14d34085aa5c1be224a4d8f7c6fbd","Extras\Editors\Emacs\ahk-mode.el")
SHA1("bab0ce1a7df6d5d5b6685120db7e369d42781993","Extras\Editors\EmEditor\ahk.esy")
SHA1("08d28148ed42b9cbb4cc815fd5f009791a289169","Extras\Editors\jEdit\ahk.xml")
SHA1("7369b52839838ac1b6e129943de005964bbf645b","Extras\Editors\jEdit\Run` this` to` install` syntax` and` clip` files` for` jEdit.ahk")
SHA1("d642ed402859bfa7ffdf1fa85e0e5db18c43c0f1","Extras\Editors\MED\MEDMclHeader.txt")
SHA1("be638c1a3fad4ed19a7fece968ec4450aaf85912","Extras\Editors\MED\MEDSynHeader.txt")
SHA1("376e2e5f4b26d90d04c8e9706ce74ea44393bc06","Extras\Editors\MED\Run` this` to` install` syntax` file` for` MED.ahk")
SHA1("7ba2a552841b39d331980c70dba7c6a77c8a39a9","Extras\Editors\Notepad++\AHK` Autohotkey.api")
SHA1("dc4925a666a672262a6f0b7c9e5f7d52c291cc87","Extras\Editors\Notepad++\Run` this` to` install` syntax` file` for` Notepad++.ahk")
SHA1("1dcdb47396435660a8e6cc4c0eab48242e8d4fe7","Extras\Editors\Notepad++\userDefineLang.xml")
SHA1("dcc4fe40ebe9c0ec4fc251986a31dcff4ed29d3a","Extras\Editors\PSPad\AutoHotkey.def")
SHA1("061f7969d51abe4c922071e398bbda8dcc561b3a","Extras\Editors\PSPad\AutoHotkey.ini")
SHA1("f30d12abda3fa21f4029f08cabd53bf80284aafe","Extras\Editors\PSPad\Run` this` to` install` syntax` and` clip` files` for` PSPad.ahk")
SHA1("8c51bc138ed39787499145d09949170e0d280368","Extras\Editors\SciTE\ahk.properties")
SHA1("be9a149f2dddad512acbba9b6a573cdf9bf06d5d","Extras\Editors\Syntax\CommandNames.txt")
SHA1("f45a1641a832c0ba129c5423a08cb513a42ca4e3","Extras\Editors\Syntax\Commands.txt")
SHA1("8a6dcd67a0dbd5f6dd1b50349c6b649e2b96cb49","Extras\Editors\Syntax\Functions.txt")
SHA1("b6b9e7ac579096a04d06d0f375dd4d58a30dff0a","Extras\Editors\Syntax\Keys.txt")
SHA1("15c2faa26015f22f7359c769b7a953bf58f4efc8","Extras\Editors\Syntax\Keywords.txt")
SHA1("df0ef8afbe78e7fb56786a3405fa8803a4710b58","Extras\Editors\Syntax\Variables.txt")
SHA1("ea5c0d38a88dd7fd988304b2ec0f27eda2f63189","Extras\Editors\Syntax\Scripts\Generate` jEdit.ahk")
SHA1("56fdf38540af21db1ae49bcf7a9179c2be5b3013","Extras\Editors\Syntax\Scripts\Generate` PSPad.ahk")
SHA1("bc16b70596cdf94503a66740ea1dbf6cb7d4b012","Extras\Editors\Syntax\Scripts\Generate` TextPad.ahk")
SHA1("4d564e1bb04be21dfc69d14a047e7ae0af1a78f5","Extras\Editors\Syntax\Scripts\Validate` master` syntax` files.ahk")
SHA1("448a0c9f16ee5558f014c22b75e4cd52b43aca6e","Extras\Editors\TextPad\AutoHotkey.syn")
SHA1("ffc31ebadce09a33b7d4874268324ae104a8c8eb","Extras\Editors\TextPad\AutoHotkey.tcl")
SHA1("38b4ce46f185b72389566f3b2f6220e86f4bceea","Extras\Editors\TextPad\Run` this` to` install` syntax` and` clip` library` files` for` TextPad.ahk")
SHA1("27a7466a5f352b5c5aef66908d96f30c4152ce5a","Extras\Editors\UltraEdit\Operators.txt")
SHA1("3738f3f5cabdddf292305d73e6a44b790cba70b2","Extras\Editors\UltraEdit\Run` this` to` install` syntax` highlighting` for` UltraEdit.ahk")
SHA1("7c404512542a374f56cf84f86369da39da1a774f","Extras\Editors\UltraEdit\Separators.txt")
SHA1("bbfe62793b5e1dc0b3c98de99b317d35cb32f968","Extras\Editors\UltraEdit\Special.txt")
SHA1("16317e1d898bb4fa619e2a314f0af188f9b6095a","Extras\Editors\Vim\ahk.vim")
SHA1("dde0f8723c07ea9a97524aa70dd74dff28a55e3e","Extras\Scripts\IntelliSense.ahk")
SHA1("83eb0b50548f8d89c1c97c6767f66b0cdc584d9c","AU3_Spy.exe")
SHA1("53e3f6328f4b6ce6e98e092245833499e8ec4db1","AutoHotkey.chm")
SHA1("10aae5e538327d5bdb54e4d9bc0c8971b2a831a3","AutoHotkey.exe")
SHA1("6ed5b1de7979fd3779e17df843a2042fa14aaace","AutoHotkey` Website.url")
SHA1("3d436ffdd69f7187b85e0cf8f075bd6154123623","license.txt")
SHA1("82d7a111724595fa77f5f59916c885d20c23473f","uninst.exe")

Run, AutoHotKey.exe
ERROR_TEST("Running AHK failed.", "Running AHK went okay.")

WINDOW_WAIT("AutoHotkey.ahk", "Press YES to create and display the sample script")
ControlClick, &No, AutoHotkey.ahk, Press YES to create and display the sample script
ERROR_TEST("Closing AHK reported an error.", "Closing AHK went okay.")

; Prevent race condition
Sleep 500

WIN_EXIST_TEST("AutoHotKey.ahk")

exit 0
