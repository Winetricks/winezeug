;
; AutoHotKey Test Script for CCleaner 2.2.0
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

; Download CCleaner, install it, sha1sum installed files, run it, verify the window exists, and exit.

DOWNLOAD("http://download.piriform.com/ccsetup220.exe", "ccsetup220.exe", "488761c2509785013cd2df8375ceb1856f7d88ed")

Run, ccsetup220.exe
ERROR_TEST("Launching CCleaner had some error.", "Launching CCleaner went okay.")

WINDOW_WAIT("Installer Language", "Please select a language")
ControlClick, Button1, Installer Language

WINDOW_WAIT("CCleaner v2.20 Setup", "Welcome to the CCleaner v2.20 Setup Wizard")
ControlClick, Button2, CCleaner v2.20 Setup

WINDOW_WAIT("CCleaner v2.20 Setup", "Please review the license terms before installing CCleaner v2.20")
ControlClick, Button2, CCleaner v2.20 Setup

WINDOW_WAIT("CCleaner v2.20 Setup", "Choose the folder in which to install CCleaner v2.20")
ControlClick, Button2, CCleaner v2.20 Setup

WINDOW_WAIT("CCleaner v2.20 Setup", "Select any additional options")
ControlClick, Button2, CCleaner v2.20 Setup

WINDOW_WAIT("CCleaner v2.20 Setup", "Completing the CCleaner v2.20 Setup Wizard")
ControlClick, Button2, CCleaner v2.20 Setup

; Not going to bother testing shortcut installation. They're spread all over, and not critical at all. We test them elsewhere anyway.

SetWorkingDir, %A_ProgramFiles%\CCleaner
SHA1("41d61372f93fd81c3921b8fda1a568287d56af84","CCleaner.exe")
SHA1("20449fee36626dc0c3130dd5e6f5e057d2b83484","uninst.exe")
SHA1("e88124ef31b37fee52b9c06e3360677fa8c9fb29","Lang\lang-1025.dll")
SHA1("21bd88c0407eb7e0e059b9252239289a1c7a8a80","Lang\lang-1026.dll")
SHA1("47702e072b2e7f0e61ccdedbc99b03603901890b","Lang\lang-1027.dll")
SHA1("e3d4d55aaeb73a06831ab14f1cffbb21cee45d29","Lang\lang-1028.dll")
SHA1("e76f77c7390120680c60b674fc13a082add3a4e2","Lang\lang-1029.dll")
SHA1("b5bcc9848a87c0d84ac869cb34b1062a5b11dbee","Lang\lang-1030.dll")
SHA1("ee87597e2d4c4d7bf0166f1c05928135b6f23b08","Lang\lang-1031.dll")
SHA1("8ac39d5de6e86f8d8db7db21d29c72709ce2408b","Lang\lang-1032.dll")
SHA1("57bd341cd25b1ad0c9ffdb50faea2fa46980797a","Lang\lang-1034.dll")
SHA1("e6c1c70974bff93ddfce7abbb359d841193a6f52","Lang\lang-1035.dll")
SHA1("50a0beafceb714f131b4ab05dbbc55b8093b4173","Lang\lang-1036.dll")
SHA1("65731d7dc8b53ab1947e886ae76dd58cf862e89f","Lang\lang-1037.dll")
SHA1("2f7b22dd6d91c84c2340cff2322d35fb571eaa8e","Lang\lang-1038.dll")
SHA1("feeda7b939d69997f15421b6853cc01d0508f053","Lang\lang-1040.dll")
SHA1("b9fce6d0b6b731d80115916790a3ede4d1e403b8","Lang\lang-1041.dll")
SHA1("bd69530bb3b00307ecb7f2ccb38c4610a3ef2ee0","Lang\lang-1042.dll")
SHA1("6690160cae545e73ff8817840a97591f9aefd8ce","Lang\lang-1043.dll")
SHA1("d57451730d79cb96078df5692167552e3815199e","Lang\lang-1044.dll")
SHA1("4f4da32629334896aa2b9844b1ccdd3d346e0e20","Lang\lang-1045.dll")
SHA1("8fcfa747233d1dac0bf6b2ddc958a3d7dd605cff","Lang\lang-1046.dll")
SHA1("e7d11bba913cb043511ee3605e19c5d67bc98a71","Lang\lang-1048.dll")
SHA1("9518be85d907d7111c335d184f09ce1c1ef70140","Lang\lang-1049.dll")
SHA1("e24da071b5623ea14dba4314efd0fcea871add07","Lang\lang-1050.dll")
SHA1("4a910ccc72d4ebd7da3e0a7ab264e3ea0b790c81","Lang\lang-1051.dll")
SHA1("ef4ae0f4f59cd2c3389071eb08c2ad6bbd5c183d","Lang\lang-1052.dll")
SHA1("1209445787a6b268c544fff82ba689e67b5821c5","Lang\lang-1053.dll")
SHA1("d268bced7e29834c9f1c7869e2dc3f8aae8d2bd0","Lang\lang-1055.dll")
SHA1("2f319d148e43a5e0899772a85d7f2fabc85d18b4","Lang\lang-1058.dll")
SHA1("6d0522a9582f4633bc68cb59c184c5f300d6de66","Lang\lang-1061.dll")
SHA1("8860e65033ce313d1770021407bd087895456003","Lang\lang-1063.dll")
SHA1("f0b2c1bb4c175d4d235d7316a56267c426f77c71","Lang\lang-1065.dll")
SHA1("8dbfc45f6c7d4d1f777367b59c944fc9155f5dd8","Lang\lang-1066.dll")
SHA1("0ffde8dd7dfb95bc00d6e4548dd0d37afbea9246","Lang\lang-1071.dll")
SHA1("096c13858fad94a8827ac28c93cfdd3e24a488c3","Lang\lang-1110.dll")
SHA1("f99c999f8f79d96d6e0cf639b1ee1d45cf58cb20","Lang\lang-2052.dll")
SHA1("ec2b302f8aa5cf1a14a0f63b9b4bf403ef0b7da3","Lang\lang-2070.dll")
SHA1("3cecfb59600f6a4023424f78f9a919bfb9fd6a29","Lang\lang-2074.dll")
SHA1("26a7a5b66db8f80c9c7cb6d8e8fe6dd4c627b338","Lang\lang-3098.dll")
SHA1("bf5a9ddd9f0c4b9aa27431dd6fccad663c4b7cbc","Lang\lang-5146.dll")

Run, CCleaner.exe
ERROR_TEST("Running CCleaner failed.", "Running CCleaner went okay.")

WINDOW_WAIT("Piriform CCleaner", "Run Cleaner")
ERROR_TEST("CCleaner window reported an error.", "CCleaner window appears to be fine.")

; Try analyzing/cleaning. This probably won't do much, but this way we're sure it doesn't crash.
ControlClick, Button1, Piriform CCleaner
ERROR_TEST("CCleaner's analyze failed.", "CCleaner's analyze appeared to run fine.")

Sleep 500

; Run cleanup
ControlClick, Button2, Piriform CCleaner
ERROR_TEST("CCleaner's cleanup reported an error.", "CCleaner's cleanup appears to be fine.")

; Pops up confirmation window
WINDOW_WAIT("", "Do not show me this message again")
ControlClick, Button1, , Do not show me this message again
ERROR_TEST("Confirming cleanup reported an error.", "Confirming cleanup appeared to be fine.")

Sleep 500

FORCE_CLOSE("Piriform CCleaner")
ERROR_TEST("Exiting CCleaner gave an error.", "CCleaner claimed to exit fine.")

Sleep 500

WIN_EXIST_TEST("Piriform CCleaner")

CLEANUP()
exit 0
