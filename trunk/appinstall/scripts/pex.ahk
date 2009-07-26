;
; AutoHotKey Test Script for PE Explorer
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

testname=pex

#Include helper_functions
#Include init_test

; Download PE Explorer, silently install it, sha1sum installed files, run it, verify the window exists, and exit.

DOWNLOAD("http://www.heaventools.com/download/pexsetup.exe", "pexsetup.exe", "508ace125dd5fea1174b19354de18b4ed1c72a5f")

Runwait, pexsetup.exe /silent

WINDOW_WAIT("PE Explorer Help")
FORCE_CLOSE("PE Explorer Help")
ERROR_TEST("Closing PE Explorer Help reported an error.", "Closing PE Explorer Help went okay.")

; Not going to bother testing shortcut installation. They're spread all over, and not critical at all. We test them elsewhere anyway.
SetWorkingDir, %A_ProgramFiles%\PE Explorer
SHA1("73d07aea06e640060437011f6d362eb5495e09ce", "history.txt")
SHA1("eecb23d82c21fdde25f528edb35a96ede773459c", "license.txt")
SHA1("ef14f0ae618753446d79688631f435c1cf66cddc", "pexdll.dll")
SHA1("7f6f7b39785fb4bb1d7b929fdbe4298afcdb0f8d", "pexdll2.dll")
SHA1("df196014bf6ae029c05238db65d70a7979a140b6", "pexforum.url")
SHA1("75c9b76df3f10af0b85b7ee89015c5ce4c82fd71", "pexplorer.chm")
SHA1("a5144f774ea812e55a6ca057cddf11fa2461d38c", "pexplorer.exe")
SHA1("1f5cc13cb35d9a69460bebc8cecaa82a21443ae2", "pexplorer.url")
SHA1("f8319d68aaf67651d5af39b4b5b581647241c78c", "readme.txt")
SHA1("ad4a4fe9c6faf6ec51ff8ab5ebdfb3ef349d1f02", "unins000.exe")
SHA1("e3bcf7fb9469a3aec2909a6c6323227733ff587f", "unmg.dll")
SHA1("c96bc6568785a0d55f9e1fd71c08f8c0ee37db16", "PLUGINS\unnspack.dll")
SHA1("b4761c25e70bd84afeb439de00044241cfb48293", "PLUGINS\unupack.dll")
SHA1("ddab98b1daa731b60e25ede93a09f085afcaa19f", "PLUGINS\unupx.dll")
SHA1("5c17252edc5e6cbf294797f030fd80041698f9b6", "HTML\order-po.htm")
SHA1("a7194dacd73b07b06ec304882ba84a356bc02430", "HTML\order-quote.htm")
SHA1("aa3c822615843e30ed687a6ae43dd16a4f1eb4f2", "HTML\order-upgrade.htm")
SHA1("fe633a457c74182a5a1fb978e9a0ae6308c8788d", "HTML\order.htm")
SHA1("8bb4042f47f7623fc8857858c8aebce31d9b8068", "HTML\img\a5cc.gif")
SHA1("31e17817d9b4edf20451b189f5027a4ba6c88a2d", "HTML\img\bbmain.gif")
SHA1("70c561555f0f33c876220421ca5e906d48b651e9", "HTML\img\bbtn.gif")
SHA1("3c1d199469874095bf95071c81cf6daf91ba211a", "HTML\img\bcleft.gif")
SHA1("0fb0fa307c6ad9ea503c2e05afd652247704ffda", "HTML\img\bcright.gif")
SHA1("f172047bb03a89735b4217f3ddf8f95e42cdd4c6", "HTML\img\bg.gif")
SHA1("70fccb14e3ae7536840dcc18723d2c4945be4eb9", "HTML\img\bleft.gif")
SHA1("2f7c5a2425655c70a7b8705f318068b7ad914565", "HTML\img\bright.gif")
SHA1("613c5d3c8ffbc3380512fdfd555cf2702cc4e856", "HTML\img\emp.gif")
SHA1("18311eba8ffcf53583bdd974ee6fea324fae1f00", "HTML\img\htoolsv5.gif")
SHA1("1e85b7b9e08ad13c3061dba849ab1f7a3bb6e5a3", "HTML\img\menuhead.gif")
SHA1("f096cda9a77bee76c9716229ec484223ef262612", "HTML\img\menuheadc.gif")
SHA1("f2f0993a36d02dd28f6246a8b52079f6d75c80fa", "HTML\img\menuheadleft.gif")
SHA1("8fc08a420b7854fb6d474a5456b55bf747108272", "HTML\img\menuheadleftc.gif")
SHA1("a1be4f647c7cc17362ddf9b06907ef574ac6545b", "HTML\img\menuheadright.gif")
SHA1("363f4b81ad223d1405fddec81af37c1fe6f86419", "HTML\img\menuheadrightc.gif")
SHA1("77187a087b23806b4e31c766438eb1014cc86523", "HTML\img\pex.css")
SHA1("39a0a669f231de4e3100896ef588c42e810152cd", "HTML\img\pex_cover.gif")
SHA1("e5f6653dd4d96a32d8affe461964978802bbbc18", "HTML\img\see_or.gif")
SHA1("82f04adff4625a84714e2d0bd2767d51130818fb", "HTML\img\tophead.gif")

Run, pexplorer.exe
ERROR_TEST("Running PE Explorer failed.", "Running PE Explorer went okay.")
; Apparently sending the window text here causes buggy behavior. According to Focht, AHK's window spy may be borked.
; For now, ignoring.
WINDOW_WAIT("PE Explorer - 30 day evaluation version")
FORCE_CLOSE("PE Explorer - 30 day evaluation version")
ERROR_TEST("Closing PE Explorer gave an error.", "Closing PE Explorer gave no error.")

; Prevent race condition
Sleep 500

WIN_EXIST_TEST("PE Explorer - 30 day evaluation version")

exit 0
