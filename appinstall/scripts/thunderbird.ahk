;
; AutoHotKey Test Script for Mozilla Thunderbird
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

testname=thunderbird

; Global variables
APPINSTALL=%SYSTEMDRIVE%\appinstall
APPINSTALL_TEMP=%TEMP%\appinstall
IfNotExist, %APPINSTALL%
{
    FileCreateDir, %APPINSTALL%
}
IfNotExist, %APPINSTALL_TEMP%
{
    FileCreateDir, %APPINSTALL_TEMP%
}
SetWorkingDir, %APPINSTALL%

OUTPUT=%APPINSTALL%\%testname%-result.txt
; Start with a fresh log
IfExist, %OUTPUT%
{
    FileDelete, %OUTPUT%
}

; Download thunderbird, silently run the installer, sha1sum installed files, run it, verify the window exists, and exit.

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
ERROR_TEST("Downloading sha1sum had an error.", "Downloading sha1sum went okay.")
DOWNLOAD("http://releases.mozilla.org/pub/mozilla.org/thunderbird/releases/2.0.0.21/win32/en-US/Thunderbird%20Setup%202.0.0.21.exe", "thunderbird-2.0.0.21.exe", "fd31056d4feb673747b3d4387243206840f57681")
ERROR_TEST("Downloading Thunderbird had some error.", "Downloading Thunderbird went okay.")

Runwait, thunderbird-2.0.0.21.exe -ms
ERROR_TEST("Installing Thunderbird had some error.", "Installing Thunderbird went okay.")

; Bug 18812
IfNotExist, %A_AppData%\Microsoft\Internet Explorer\Quick Launch\Mozilla Thunderbird.lnk
{
    FileAppend, Quick Launch shortcut wasn't created. Bug 18812 still present. TODO_FAIL.`n, %OUTPUT%
}
Else
{
    FileAppend, Quick Launch shortcut present. Check bug 18812. TODO_FIXED.`n, %OUTPUT%
}

IfNotExist, %A_DesktopCommon%\Mozilla Thunderbird.lnk
{
    FileAppend, Common desktop shortcut wasn't created. Test failed.`n, %OUTPUT%
}
Else
{
    FileAppend, Common desktop shortcut present. Test passed.`n, %OUTPUT%
}

IfNotExist, %A_ProgramsCommon%\Mozilla Thunderbird\Mozilla Thunderbird (Safe Mode).lnk
{
    FileAppend, Common programs safe mode shortcut wasn't created. Test failed.`n, %OUTPUT%
}
Else
{
    FileAppend, Common programs safe mode shortcut present. Test passed.`n, %OUTPUT%
}

IfNotExist, %A_ProgramsCommon%\Mozilla Thunderbird\Mozilla Thunderbird.lnk
{
    FileAppend, Common programs shortcut wasn't created. Test failed.`n, %OUTPUT%
}
Else
{
    FileAppend, Common programs shorcut present. Test passed.`n, %OUTPUT%
}

Setworkingdir, %ProgramFiles%\Mozilla Thunderbird
SHA1("6f203e132f3e147378ce586e2abc5cac6fa3f306", "chrome\icons\default\abcardWindow.ico")
SHA1("3cb338ad9d6346c0410d9a0bef0c163656ecc046", "chrome\icons\default\addressbookWindow.ico")
SHA1("0259e5ab91a6f0981f3d567b0cdcce9b44b913ce", "chrome\icons\default\messengerWindow.ico")
SHA1("f99820f7bd51820d359d2d7bdb01db7c8c84701b", "chrome\icons\default\msgcomposeWindow.ico")
SHA1("9e186d35705f1b04db48d3911f990626095891af", "chrome\classic.jar")
SHA1("27806e1908e6476c9e5b19e6d0f2ad10091b090a", "chrome\classic.manifest")
SHA1("92930b71bd1193968b9601cff85171cc5088b5df", "chrome\comm.jar")
SHA1("aca646e85b05a834c2f0f662be3083f1302c705f", "chrome\comm.manifest")
SHA1("a708dc74d1fea3ae633979cff0568e3d043b54f8", "chrome\en-US.jar")
SHA1("46005e810fbd65e25afa46a95956ed0abee8dc82", "chrome\en-US.manifest")
SHA1("c877aabe7047f3f0b293c189d9e0ceda06416e4a", "chrome\messenger.jar")
SHA1("049f0489321e85093961be406fbcd029880d5048", "chrome\messenger.manifest")
SHA1("e9244520d252566fe30b59c2ab0be01292579963", "chrome\newsblog.jar")
SHA1("04898ec768ef84e9231a1f36625871d0bbbdce15", "chrome\newsblog.manifest")
SHA1("809c512299211daab33b2284e382d40ab852c4dc", "chrome\pippki.jar")
SHA1("4608e7571ad013787dcd68f23ae385b29c5691d4", "chrome\pippki.manifest")
SHA1("3b6b8717093ccc76fb5f3a5905adeb7f6c41786a", "chrome\toolkit.jar")
SHA1("fa34f709be4ada601ed7396740f9c47b871892ff", "chrome\toolkit.manifest")
SHA1("083252eeeaa22080951ddd3bfb56aada2dfe6c9a", "components\jar50.dll")
SHA1("5ba15d5d912aa77e8028b89b65eb1a8756f74f13", "components\jsconsole-clhandler.js")
SHA1("9723a5cd60ab8903598c3a2b752697b8da2d0e8b", "components\jsd3250.dll")
SHA1("8dae8f0e25d07ba55ff5e060e504eea7fa4c7f71", "components\mail.xpt")
SHA1("2d96a6077522a91daeb38a9c118a00997b73bb94", "components\mdn-service.js")
SHA1("e20bcfd1e6c0439116dc47a4baf9b956364b8a91", "components\myspell.dll")
SHA1("4a789045542e011ff28735fed972ae13d492824d", "components\newsblog.js")
SHA1("d0140bcd4e0e52e88970a1e171786d79cd03ec02", "components\nsAbLDAPAttributeMap.js")
SHA1("1ad99436b0cafafe31907f4754abbd34ff2361b1", "components\nsCloseAllWindows.js")
SHA1("17e3e793d24273ee92d922d5d0fd712d99fe99b1", "components\nsExtensionManager.js")
SHA1("3c2236b17ba0e8c4a58b66acf366d4f137ac15fa", "components\nsHelperAppDlg.js")
SHA1("fc64a6e1479733ca9f4879f404f76105ce4e27d8", "components\nsLDAPPrefsService.js")
SHA1("f5f42a6d460ba2617652edd054649877356c86e1", "components\nsMailDefaultHandler.js")
SHA1("c22f25d786a62fb2e58a110be487d96a63767c75", "components\nsPhishingProtectionApplication.js")
SHA1("59d0af7c56d1479c1a1f4880076beaf577461a8d", "components\nsPostUpdateWin.js")
SHA1("e9e75314715e36c18205d20ecd43e68445ca59d7", "components\nsProgressDialog.js")
SHA1("018c35966f308db51095b4eaf4f9ce6392b23b1d", "components\nsProxyAutoConfig.js")
SHA1("6e34b30ea53b17303f50953617fd8fb05cb0b9a7", "components\nsSetDefaultMail.js")
SHA1("2a60f08213e60e5953eebeb0055f6adf885f1464", "components\nsUpdateService.js")
SHA1("94bb49ae6e5ff54e39df71b61d7763159c64b88a", "components\nsUrlClassifierLib.js")
SHA1("1c123423f866409bcb741216d776f1ed097f168c", "components\nsUrlClassifierListManager.js")
SHA1("b750ea3928898b74d2cb52437449b7f0baa62f22", "components\nsUrlClassifierTable.js")
SHA1("6527b1d315f7274c31e63536c169cefe35496239", "components\nsURLFormatter.js")
SHA1("175220ab7ca2d2e5a94663c3fcfe86994779e468", "components\offlineStartup.js")
SHA1("867fd5354889c4f6d6f7da7830f18982f9333607", "components\smime-service.js")
SHA1("9d200a3765f5bcfc839de0808737ad39ed99a720", "components\spellchk.dll")
SHA1("352413f28cb41b35ecfb9eafb6cd2006411112a3", "components\xpcom.xpt")
SHA1("1899786c6afe6d4bb5197bd611e180aaad3b50d9", "components\xpinstal.dll")
SHA1("6b7554f4fb3f1a4f22c1b09f0d1e84eb9438450b", "defaults\autoconfig\platform.js")
SHA1("7fb3a79e959cf46c613599568be8b93bd647652b", "defaults\autoconfig\prefcalls.js")
SHA1("f8acdee51e3f7ee5654a6d405fff508503273565", "defaults\pref\all-l10n.js")
SHA1("fc288b48b6ee1b12f63ec21d5e27d148f11d4090", "defaults\pref\all-thunderbird.js")
SHA1("bd2ba13bea218eb398f956b2b8eea2ed93737e3f", "defaults\pref\channel-prefs.js")
SHA1("1dc4dad70ffea659117f74bdaac1f87e10a20ad6", "defaults\pref\composer.js")
SHA1("dd283b0a2d8f3f62148e864da6dda1dcb5a3ddbf", "defaults\pref\mailnews.js")
SHA1("5e14fb526ba20764fb60a731fdbc69662fe2057d", "defaults\pref\mdn.js")
SHA1("9c3c001dbd851d080f46d4249c38472fcd4decad", "defaults\pref\smime.js")
SHA1("93f2de751378ec91691af333a34f984aea60e4d5", "defaults\pref\thunderbird-branding.js")
SHA1("2d8aee4b5cbfb5e1c08f2a4c9af2110bc1262b11", "defaults\profile\localstore.rdf")
SHA1("95b7c14deec136a9fd629b253e213c3155c40536", "defaults\profile\mimeTypes.rdf")
SHA1("8d94cf5c736408c218bd7e483cea3357124d232f", "defaults\profile\prefs.js")
SHA1("f3662846acc311ccdc7bc0525b62b50f7e2fbacc", "extensions\talkback@mozilla.org\components\BrandRes.dll")
SHA1("8945358f8d182e580023ee1e6666b4adb89d9c40", "extensions\talkback@mozilla.org\components\fullsoft.dll")
SHA1("5d52430ca19c0c39d3c2182939b91127261c734c", "extensions\talkback@mozilla.org\components\master.ini")
SHA1("05b5597139abe80492d455f4d734ac0aad375de4", "extensions\talkback@mozilla.org\components\qfaservices.dll")
SHA1("caeaf799b0b4a16b017498c9869981970c6cd57a", "extensions\talkback@mozilla.org\components\qfaservices.xpt")
SHA1("4fd926262bfff34588df90847b3e5058ef9f2608", "extensions\talkback@mozilla.org\components\talkback-l10n.ini")
SHA1("ef518b209b07c6830d83999edae789cd3e7ae385", "extensions\talkback@mozilla.org\components\talkback.cnt")
SHA1("c4a28e7bdecb5d11a7d1aaf042cd0eecbd7108a6", "extensions\talkback@mozilla.org\components\talkback.exe")
SHA1("29e67aff493587d28abd760ad30906173936fab6", "extensions\talkback@mozilla.org\components\talkback.hlp")
SHA1("da39a3ee5e6b4b0d3255bfef95601890afd80709", "extensions\talkback@mozilla.org\chrome.manifest")
SHA1("7b738175a915c51a7ed13bf31eca0f8ab34aadaf", "extensions\talkback@mozilla.org\install.rdf")
SHA1("66855c47c10d65d92fad5a478460cee71897bc06", "dictionaries\en-US.aff")
SHA1("ba119761e911604012a348f9c7358822e2f0467c", "dictionaries\en-US.dic")
SHA1("c289bb5fd02aa84e60778a7721b1ee5943d7666b", "greprefs\all.js")
SHA1("2989d8bd94c950d7173945de2324240c90cba74d", "greprefs\security-prefs.js")
SHA1("a0a00b69c3450cb5c66b9cc06fb94841c6963875", "greprefs\xpinstall.js")
SHA1("71b51a688b4c7f20976e02baf9b908ed765286f2", "isp\en-US\gmail.rdf")
SHA1("a98edef606d7d5d1a8fec531f3062a586a92e871", "isp\rss.rdf")
SHA1("150edbd16af80b116778c65a2a28b88fbb5e24b3", "isp\SpamAssassin.sfd")
SHA1("285ed59952c34c7a526675bc21bfd01999bc0d34", "isp\SpamPal.sfd")
SHA1("2981b43e6045ff35d34a1027516182447531e0d6", "res\dtd\xhtml11.dtd")
SHA1("532df7db5f7f0e656cb79007edd48fb117836825", "res\entityTables\html40Latin1.properties")
SHA1("59b7eb9d49626e5b6daf102e4cbd70d889df63e3", "res\entityTables\html40Special.properties")
SHA1("374927a30f80ba9ee2a005b6f31182c5b19c0404", "res\entityTables\html40Symbols.properties")
SHA1("177481c2b5ce5618a40d6fc8c6d61e3eea492d76", "res\entityTables\htmlEntityVersions.properties")
SHA1("c4c48f26418aeb4bbf26c309d8c797e107a07fb2", "res\entityTables\transliterate.properties")
SHA1("baf4760e27fbf4413fccfaecbf281dec06169ab7", "res\charsetalias.properties")
SHA1("3bd185d45ee0a89e5f136e3bc94c9dbfe2cc6973", "res\charsetData.properties")
SHA1("86d748c1a251e8fc0df91ce3f3a8c3f8994b063f", "res\EditorOverride.css")
SHA1("7554be160c70d44b0d116ae80be38e9624a87e0f", "res\forms.css")
SHA1("c0b32c82d1580b7c9a6fde4eded9612530d284c9", "res\grabber.gif")
SHA1("e3345fb059be0a17fec9f212f97eace0fe4ae119", "res\hiddenWindow.html")
SHA1("ab28c3de505bfdab6f2b549fba85549bf6ddd154", "res\html.css")
SHA1("57833f48db56bd70bf538c424f6c5719fbbc7437", "res\langGroups.properties")
SHA1("594976f3906f91f2a1a2199f43e396f63e8ff6d9", "res\language.properties")
SHA1("e4c09185d7d6b9e0a08abb5ba828bdb8e59223a0", "res\quirk.css")
SHA1("24897012bc14cac8aa27b32f5c3cae0a398f4f18", "res\table-add-column-after-active.gif")
SHA1("33675f50d10cbf4e7de38068a8c35692aa1de8be", "res\table-add-column-after-hover.gif")
SHA1("bffa6ac37f2d6aa9f030e7b428bc5ca5ca55218b", "res\table-add-column-after.gif")
SHA1("a1e2ab1b77101c28e2ce585f0d49528466318a22", "res\table-add-column-before-active.gif")
SHA1("6aa75faf4e9d7ce0c743d9f014d1349822efd64d", "res\table-add-column-before-hover.gif")
SHA1("d07472295c783f52842c727abe8e568bde27bc58", "res\table-add-column-before.gif")
SHA1("86c13feda9879e0bb9ed9c38766a599192cf4880", "res\table-add-row-after-active.gif")
SHA1("6cd76a918b50021f3baf7d0f535f1e7588232f52", "res\table-add-row-after-hover.gif")
SHA1("9f55167f4843d25452419ad8b6856c491a7919d5", "res\table-add-row-after.gif")
SHA1("edd33b631007828da2f369e2c53460075dcfcc45", "res\table-add-row-before-active.gif")
SHA1("226b23cd455176340c8c72f21481d6fa0ba438c7", "res\table-add-row-before-hover.gif")
SHA1("71d14238f799191d3196f662de97445b2544e56f", "res\table-add-row-before.gif")
SHA1("67c0bbae8ac6dd12cb66621f3539fae6971d91e0", "res\table-remove-column-active.gif")
SHA1("389daf6bcd0ba84a413dce4aff02ae9800eb1061", "res\table-remove-column-hover.gif")
SHA1("891c963cb3c26628dcb18db5653eaca5275b0f9e", "res\table-remove-column.gif")
SHA1("67c0bbae8ac6dd12cb66621f3539fae6971d91e0", "res\table-remove-row-active.gif")
SHA1("389daf6bcd0ba84a413dce4aff02ae9800eb1061", "res\table-remove-row-hover.gif")
SHA1("891c963cb3c26628dcb18db5653eaca5275b0f9e", "res\table-remove-row.gif")
SHA1("f9cd536c535fe407f4f6c7f0a80ee65a91b0bc5c", "res\ua.css")
SHA1("f2e30f66a696051452e49245f1be3f72161ee5e7", "res\wincharset.properties")
SHA1("52e54b873bc99dc7d458d1394daa1733f5e72a4a", "uninstall\helper.exe")
SHA1("875dcd072daa4b12652a4dc52dbc87a7760edd85", "AccessibleMarshal.dll")
SHA1("195ccfa7ca8482e5818503e959ae341fa4cc5505", "freebl3.chk")
SHA1("acf9593101ea058212270e832bb5f88967f34394", "freebl3.dll")
SHA1("69225420729c6a9d534e770acef2cdf43cea9851", "js3250.dll")
SHA1("985726f91eff28045410bd4a7bb6fcccf322bf58", "license.html")
SHA1("58a89848a01119ca238c247c03f41ff7d99f032e", "LICENSE.txt")
SHA1("aff8f70dc422fcea9df4beaca52c0e5a3a40f878", "MapiProxy.dll")
SHA1("e5fbc8bfa2beea9fccb6659df867dc82a4d4d43d", "mozMapi32.dll")
SHA1("1405516dc2044c9a8b1d4ee4c9a7dfe7266dff58", "nsldap32v50.dll")
SHA1("7ade8ee31b78ee4c594785d72be6e57044ff0ef4", "nsldappr32v50.dll")
SHA1("2ead8892b0a9175c725774995d075c99ead41666", "nspr4.dll")
SHA1("88114415189b581434d5852e80220d1a6290322a", "nss3.dll")
SHA1("4bd0cdaad4e0343713f8a787b2a27aacc37c0a80", "nssckbi.dll")
SHA1("1a9e1c8823ed9fe93860f8f10930e2e0e385d5a2", "plc4.dll")
SHA1("9cbf6d75d5746f89df81f28d178a628d455b4630", "plds4.dll")
SHA1("6935c215f907b4d84b2cb941de1c8300e4aedd87", "README.txt")
SHA1("81dfbbb1e5087cc754851aa7293559fae83330c3", "smime3.dll")
SHA1("2e21e9f5f48559983efeadc5529a9d93c5741ddf", "softokn3.chk")
SHA1("e5e3443df183c65025f27348dea6017d7ea8ad07", "softokn3.dll")
SHA1("11245be20d029c349d84ed1ce528bef89bd885dd", "ssl3.dll")
SHA1("1fd3d5744bb7712163220b852079e70c8e230a22", "thunderbird.exe")
SHA1("690570b473e2debcba95c82bc0e3642151aba62f", "updater.exe")
SHA1("cb2255c131aac924d709efa86bc3571b63a7a841", "updater.ini")
SHA1("5ee466f1cda0ffd9d1c0947f0a8cde51eababb7e", "xpcom.dll")
SHA1("a1c582bcbcbb114bfeecf1f91dc5c830d61baee5", "xpcom_compat.dll")
SHA1("9bef2e1e7cb7afb42324e054d813016b4449e4c9", "xpcom_core.dll")
SHA1("a324882f5efafa2a7588307df95dff8466bc2ed6", "xpicleanup.exe")
SHA1("ce42691b8dca8dee6b57f98d6369cde113cca451", "xpistub.dll")

Run, thunderbird.exe
ERROR_TEST("Running Thunderbird failed.", "Running Thunderbird went okay.")

WINDOW_WAIT("Import Wizard", "")
ControlSend, MozillaWindowClass16, {Escape}, Import Wizard
ERROR_TEST("Closing Import Wizard reported an error.", "Closing Import Wizard went fine.")

; Prevent race condition
Sleep 500

WINDOW_WAIT("Account Wizard", "")
ControlSend, MozillaWindowClass49, {Escape}, Account Wizard
ERROR_TEST("Account Wizard reported an error.", "Account Wizard ran fine.")

; Prevent race condition
Sleep 500

WINDOW_WAIT("Account Wizard", "")
ControlSend, MozillaWindowClass1, {Enter}, Account Wizard
ERROR_TEST("Account Wizard's cancel box reported an error.", "Account Wizard's cancel box ran fine.")

; Prevent race condition
Sleep 500

WINDOW_WAIT("Mozilla Thunderbird", "")
ERROR_TEST("Thunderbird's main window reported an error.", "Thunderbird appeared to launch fine.")

; Prevent race condition
Sleep 500

PostMessage, 0x112, 0xF060,,, Mozilla Thunderbird
ERROR_TEST("Exiting Thunderbird gave an error.", "Thunderbird claimed to exit fine.")

; Prevent race condition
Sleep 500

IfWinExist, Mozilla Thunderbird
{
    FileAppend, Thunderbird didn't exit for some reason. Test failed.`n, %OUTPUT%
}
IfWinNotExist, Mozilla Thunderbird
{
FileAppend, Thunderbird exited successfully. Test passed.`n, %OUTPUT%
}

CLEANUP()
exit 0
