;
; AutoHotKey Test Script for Notepad++
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

testname=notepadpp

#Include helper_functions
#Include init_test

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
DOWNLOAD("http://downloads.sourceforge.net/sourceforge/notepad-plus/npp.5.4.4.Installer.exe", "npp.5.4.4.Installer.exe", "37f94931cc1cb61d5d531eca1137765a992358ad")

Runwait, npp.5.4.4.Installer.exe /S
ERROR_TEST("Installing Notepad++ had some error.", "Installing Notepad++ went okay.")

Sleep 1000

SetWorkingDir, %A_AppData%\Notepad++
CHECK_DIR("plugins\config")
SHA1("cae0efb29e81ecb9c58360a68416e584d12fe8b3","contextMenu.xml")

SetWorkingDir, %A_ProgramFiles%\Notepad++
SHA1("957cceeccff184569875a10222c8b795d370dc6c","change.log")
SHA1("ff0f231c1761131f651378f09027a057dcaa91b7","config.model.xml")
SHA1("f05cde246f8d1c31ed3a495263ca499bcde10471","langs.model.xml")
TODO_SHA1("f05cde246f8d1c31ed3a495263ca499bcde10471", "19d00982b2e61b5b3dbc72bcb26c53e441807dd6", "langs.xml")
SHA1("30060e0422b28abdadf5b96348f6e54300cf9fa1","license.txt")
SHA1("0def5d325789f5e24d758160ee1f9755b61fe052","LINEDRAW.TTF")
SHA1("1facc7d36bdefddb5c76f6951c9445c7e8e9024b","notepad++.exe")
SHA1("b098b1dd9eb3d73b0ba14156bdfe6befa6703df5","nppcm.dll")
SHA1("dc9a059033fd92bbc677364fef8abf58b04dab7d","NppHelp.chm")
SHA1("7818cc02057fd7f899ad5f67c17e678052b4e7ca","readme.txt")
SHA1("e1d39f163bb3e0223f5b3bd12623b936f5f96be6","SciLexer.dll")
SHA1("8b06a25037e1d31ee61c062b787537e1101e17af","shortcuts.xml")
SHA1("545390d609218647e46e4bcca8210f0741e53582","stylers.model.xml")
SHA1("5bf16608db4d9db814f75bb4bf75894be48d16c4","uninstall.exe")
SHA1("5f3746ab476a00f50eb1756369991580b1b061fa","localization\albanian.xml")
SHA1("01169bcdb4ffd1c5bf9e2d4e90d2b26554dca067","localization\arabic.xml")
SHA1("2310be49e5f42d3b852fbd7f739a1460071776f8","localization\aranese.xml")
SHA1("99dca671c5130ef12f2914c0de9c48efc9a06807","localization\basque.xml")
SHA1("d667082f17ef0a31bb6a77f1f01724d3c28bf302","localization\belarusian.xml")
SHA1("5a1b08aa7e81da9239bbb026ffadae59f1a6ed57","localization\brazilian_portuguese.xml")
SHA1("09362607cce25e694658dafbde454cbd6553b845","localization\bulgarian.xml")
SHA1("f67f4e764938426ec7e10ebc90177dcea2f1d9a3","localization\catalan.xml")
SHA1("da7eec29376d0c6c871b7ee91b952ca5b9c711ff","localization\chineseSimplified.xml")
SHA1("0c1c83fbe6f7efd232aad269cc539bba376ed182","localization\chinese.xml")
SHA1("0025d8b1841c3c0ffb12735be17ae4fab679337d","localization\croatian.xml")
SHA1("7f03b4457e976135f81bc6e5d1f5e61b066fd520","localization\czech.xml")
SHA1("718f3217db5b204f546c4812b914b8fba6b86d37","localization\danish.xml")
SHA1("e1a39253c235b9bb05ed849d4a3f381c3557879b","localization\dutch.xml")
SHA1("f15da9b4e6055f1c84505d963abe4e79d396b76e","localization\english.xml")
SHA1("e123c5221bb531c6dd12a4ee209a1a7eead9d433","localization\extremaduran.xml")
SHA1("9657943f51772a96c6540c19da332d24d400eac4","localization\farsi.xml")
SHA1("d2b845f35e5969645af01925dc18f281739907d0","localization\finnish.xml")
SHA1("a49fae5e8852209a6d2ce413111b42f7d09f2767","localization\french.xml")
SHA1("209a8c8ebdc691ca1764b74a7577a65654a49e2d","localization\friulian.xml")
SHA1("2d827e417dc66a35e5f47cca0b99790d317d4fca","localization\galician.xml")
SHA1("218d63a9fa952d0b6dbd0653dcce3834671b678a","localization\georgian.xml")
SHA1("dfdbd4efbc3c260ba5475f81f01ceb7d269bc403","localization\german.xml")
SHA1("8a5ed160e6e446456adb639d0fdfb38c1638d54f","localization\greek.xml")
SHA1("5743c27f7d30791166da2132a2e8f0de3206eaa0","localization\hebrew.xml")
SHA1("a2f0f70177f228c44e31657a5972808df75d2e84","localization\hungarianA.xml")
SHA1("6e47a559e84f344a58b7659723183843f0a870ac","localization\hungarian.xml")
SHA1("ccdc03af59fb9cb93f41f8177af12f1f74dcfec5","localization\indonesian.xml")
SHA1("4ac693e2ff23c3e3f1e25a2ac53ec07e470d48d3","localization\italian.xml")
SHA1("46b270bee10194c6d69b235ba5a4c71f213968a5","localization\japanese.xml")
SHA1("4ba472426d094b42bff297e59e31a21b7dd9a600","localization\korean.xml")
SHA1("1f329349e1f22358c7e54e519c5746b098130a11","localization\lithuanian.xml")
SHA1("39605cc6f938acecd25ab3a69eea301309d2a425","localization\luxembourgish.xml")
SHA1("36ce3e1e267cdb7bbd7735be2dc2dfe0bfbf20af","localization\malay.xml")
SHA1("c73a952fe14500db7eebc18cff3213e5abef9816","localization\norwegian.xml")
SHA1("3103b6bd4d564a44bcbda0bd0df3431e539d7827","localization\nynorsk.xml")
SHA1("4ea1a902be7d4bf64cedc6b21db92c07c184c066","localization\occitan.xml")
SHA1("8b0575800344b83532b406b15f94e7fb40d14e97","localization\polish.xml")
SHA1("0f851fb05d576583d5ff7a2e3dbe930e18b6cea4","localization\portuguese.xml")
SHA1("44a4d2517535a8b5f79b3dc8783c0cb7124ff543","localization\romanian.xml")
SHA1("a45e9f1b651bbc24515cf34c20edb49fc8cdf06f","localization\russian.xml")
SHA1("c1f3286eb08ba8411fc9e043b5dcf5c516acf160","localization\samogitian.xml")
SHA1("4c8dceecc7eab24f3605ae19f73ca634e1891af7","localization\serbian.xml")
SHA1("1a5261a04af0431b5599bbcd15a24550c582fa6d","localization\slovakA.xml")
SHA1("2e9e7c934d30a45c54e53db5df2e2890ad3a8c0a","localization\slovak.xml")
SHA1("c332af12232a27a2a7afb03994d60f4464a8df69","localization\slovenian.xml")
SHA1("671f9219c6df569f40cf23bf6ee14da649325950","localization\spanish_ar.xml")
SHA1("7c43f1a003fcde45992947180c5c4b2e6d639736","localization\spanish.xml")
SHA1("cf9bacb90baad67d44cb5780bb4cfea2d1c85559","localization\swedish.xml")
SHA1("f28ae7fa6c99e22e07716046249839122fa1aa10","localization\thai.xml")
SHA1("6d6fa3cdb7ced86ef72a7143e8486f45f449790d","localization\turkish.xml")
SHA1("95f1bee23516516e9db65324a24e4b4e02e58984","localization\ukrainian.xml")
SHA1("4af26ce111edd621a6d1764dfa5a229052c75e70","plugins\APIs\actionscript.xml")
SHA1("7b18d04ea21a8ed2257c50661acf9d1ea60d9228","plugins\APIs\awk.xml")
SHA1("87a7fe27a389d363076073979136e22251469a20","plugins\APIs\cpp.xml")
SHA1("427e170083be87d570df3f9ea4b0eff0eb60a8f4","plugins\APIs\css.xml")
SHA1("aeac86b2ba5d17389033c81acf7612b2fbc2943b","plugins\APIs\cs.xml")
SHA1("b6010b4b59128f9d16abd9e8d8ccf521ed6e4eb8","plugins\APIs\c.xml")
SHA1("b37c56bc0d889cf15239dbcfeafaaa98cf2af9fd","plugins\APIs\html.xml")
SHA1("49e78241eafb3e49ecff0ed56e68c24514b47313","plugins\APIs\javascript.xml")
SHA1("29dbe1ca871dd24765e9421ac1c3420312cba1de","plugins\APIs\java.xml")
SHA1("8433177f8656755b0f79d96188f3de085520d75e","plugins\APIs\lisp.xml")
SHA1("30eb1ac0edce186a695f136507495d8dacc4963a","plugins\APIs\nsis.xml")
SHA1("1c16e26ff53833c04015db1b522a9f4e0234bfca","plugins\APIs\perl.xml")
SHA1("ec8fafe0d5908f29db32147f0f13c92347684cce","plugins\APIs\php.xml")
SHA1("0e6945eecf3065847973ed8a754e75f4f5f0f20b","plugins\APIs\python.xml")
SHA1("413141253cf170a010f7f3a05a9ee1cfd4d37e25","plugins\APIs\rc.xml")
SHA1("e44bddf3bfefb169512725ff9401e26a300a1028","plugins\APIs\sql.xml")
SHA1("3c9a5f7b235f1c7290ddce60ddc52df156d4d39f","plugins\APIs\tex.xml")
SHA1("cfd5aca98e8f634d6f6b583f1e5a56e0bdbf2053","plugins\APIs\vb.xml")
SHA1("668325f597bb9fa517e41f304f07c5d0a0421160","plugins\APIs\vhdl.xml")
SHA1("d4ff6d0b283f7b2b8d1792b0c9671d9afb43d3f7","plugins\APIs\xml.xml")
SHA1("9b85e6b1f57dfa83298ce869209eed10dbc0d2ca","plugins\Config\tidy\AsciiToEBCDIC.bin")
SHA1("58722272c5dc7fd98772827086e209f2c4486013","plugins\Config\tidy\libTidy.dll")
SHA1("415f1e35d39557467afd30506b6f8e4475ac7af0","plugins\Config\tidy\TIDYCFG.INI")
SHA1("fa124ae5503b6a569b55bb1329108cd04028576e","plugins\Config\tidy\W3C-CSSValidator.htm")
SHA1("530344a41c7be15d669d09339e5fa37b539c7a06","plugins\Config\tidy\W3C-HTMLValidator.htm")
SHA1("2a6410c7567f086a8d9dfe168ab1c8752fcc308a","plugins\doc\FTP_synchonize.ReadMe.txt")
SHA1("7930946ac2b2efb3ef03f0f6feae0bfe2861a93c","plugins\doc\NppExec_Guide.txt")
SHA1("dfaf0a89da3fdea0627347d967c47a1bfa1e88ac","plugins\doc\NppExec_TechInfo.txt")
SHA1("80436ecb42440c0361930da4a1224a6561e7fb31","plugins\doc\NppExec.txt")
SHA1("0050bbc60a2ab2557e2b5027b593a3dd898d9915","plugins\doc\NPPTextFXdemo.TXT")
SHA1("184a6b4b641f7f1c01213d28bd3b8f250e4d95be","plugins\docMonitor.dll")
SHA1("9779fbc416540842a57f1875031df647eb6fe770","plugins\FTP_synchronize.dll")
SHA1("630665e2a4e704509b9d02f6fb8b6918a51d098d","plugins\mimeTools.dll")
SHA1("806635d3db4dc41acbcd8147e9dd00b6928fc576","plugins\NppExec.dll")
SHA1("99af84474a05b94d6268be88f4e3b18ae25433a0","plugins\NppExport.dll")
SHA1("99bbb336ef9fba87f87a769b7ff3103c069949f6","plugins\NppNetNote.dll")
SHA1("8f7a5817bf696f9e34f38a360574b62686579404","plugins\NppPlugin_ChangeMarker.dll")
SHA1("a0cf27e0d669adf2347ba0929526de8477486bf0","plugins\NppTextFX.dll")
SHA1("9f4990bfdfbea105d14f1288142e5f0d92573719","plugins\SpellChecker.dll")
SHA1("4a2d8c5bbb851b59230a433bd43c7d206bde6317","themes\Black` board.xml")
SHA1("d788580f8f2dc0e143a1d205dfd37c2eb79ac16c","themes\Choco.xml")
SHA1("fd045e58af1a026439c3a2037bd73a4b6cc7e70c","themes\Deep` Black.xml")
SHA1("2b13362d24c00724d3683a39eff67d82b4f443e0","themes\Hello` Kitty.xml")
SHA1("1be666519aa3477323813b607b45b95f4318cc07","themes\Mono` Industrial.xml")
SHA1("0e36bdaac8958c08f165f5a12abcd2c585bcc8ef","themes\Monokai.xml")
SHA1("6dea3ec74a463a14d5a8654327ab175077454a22","themes\Obsidian.xml")
SHA1("90888127d1dda5b324d0ab39695dc2413f879315","themes\Plastic` Code` Wrap.xml")
SHA1("f80c5d2fcadaa36592307c2c99bb9810a73bc7e8","themes\Ruby` Blue.xml")
SHA1("21b04017a352c61776842dd6298ce46a886e5571","themes\Twilight.xml")
SHA1("0e754cc06df94c019dcec613c92558f663940ff6","themes\Vibrant` Ink.xml")
SHA1("c20e5a8eca2bcf7564c7d5215bb7fd5c48a57abb","themes\vim` Dark` Blue.xml")
SHA1("fcef5833d8df948d8c959c331ccd5c80ff7b55d1","updater\getDownLoadUrl.php")
SHA1("8624bcdae55baeef00cd11d5dfcfa60f68710a02","updater\gpl.txt")
SHA1("53b3c5c1b88bd003962d8a38ded6141e7cf9758b","updater\GUP.exe")
SHA1("fa43f4268889cb8777c1332d49e8cfeaa2eda103","updater\gup.xml")
SHA1("06fcd9198d4887d39356fb89bea78790b4811631","updater\libcurl.dll")
SHA1("e7d563f52bf5295e6dba1d67ac23e9f6a160fab9","updater\License.txt")
SHA1("e1221e827de92c13c8a60fa0af537d79dced6f33","updater\readme.txt")

; Application bug
SetWorkingDir, %A_ProgramFiles%\Notepad++\localization
IfExist, new 1
    {
    FileDelete, new 1
    ERROR_TEST("Deleting 'new 1' reported an error", "Deleting 'new 1' went fine.")
    }
IfExist, new 1.txt
    {
    FileDelete, new 1.txt
    ERROR_TEST("Deleting 'new 1.txt' reported an error", "Deleting 'new 1.txt' went fine.")
    }

Run, %A_ProgramFiles%\Notepad++\Notepad++.exe
ERROR_TEST("Launching Notepad++ reported an error", "Notepad++ launched fine.")

WINDOW_WAIT("new 1 - Notepad++", "Highlight all")

; Try typing some text:
Send, This is some text in Notepad{+}{+}
ERROR_TEST("Typing text in Notepad++ reported an error", "Typing text in Notepad++ went fine.")

; Close & save
Send, ^s

Sleep 1000
; Wine bug 19249. On windows, title = 'Save As'. On Wine, 'Save'
IfWinExist, Save As
{
    FileAppend,  Save window is named 'Save As'. Bug 19249 TODO_FIXED.`n, %OUTPUT%
}
Else IfWinExist, Save
{
    FileAppend,  Save window is named 'Save'. Bug 19249 TODO_FAILED.`n, %OUTPUT%
}
Else
{
    FileAppend, Save window not found. This is bad. Test failed.`n, %OUTPUT%
    exit 1
}

; On Windows, the text is automatically selected
clipboard =
Send, ^c
if clipboard = new 1
    {
        FileAppend, Clipboard == 'new 1'. Bug 18455 TODO_FIXED.`n, %OUTPUT%
    }
    Else
    {
        FileAppend,  Clipboard != 'new 1'. Bug 18455 TODO_FAILED.`n, %OUTPUT%
    }

Send, {Enter}

WinWait, Save failed, ,5
    if ErrorLevel
    {
        FileAppend, 'Save failed' didn't appear. Bug 18853 TODO_FIXED.`n, %OUTPUT%
    }
    Else
    {
        FileAppend, 'Save failed' appeared. Bug 18853 TODO_FAILED.`n, %OUTPUT%
        IfWinNotActive, Save failed
            {
            WinActivate, Save failed
            }
        ControlClick, &OK, Save failed
    }

IfExist, new 1
    {
        FileAppend, File 'new 1' was created. Bug 18853 TODO_FIXED.`n, %OUTPUT%
        FileDelete, new 1
        ERROR_TEST("Deleting 'new 1' reported an error", "Deleting 'new 1' went fine.")
    }

Send, ^!s
Sleep 500
IfWinExist, Save As
{
    FileAppend,  Save window is named 'Save As'. Bug 19249 TODO_FIXED.`n, %OUTPUT%
    ControlSetText, Edit1, new 1.txt, Save As, Save &in
    Send, {Enter}
}
Else IfWinExist, Save
{
    FileAppend,  Save window is named 'Save'. Bug 19249 TODO_FAILED.`n, %OUTPUT%
    ControlSetText, Edit1, new 1.txt, Save, Save &in
    Send, {Enter}
}
Else
{
    FileAppend, Save window not found. This is bad. Test failed.`n, %OUTPUT%
    exit 1
}

Sleep 500
PostMessage, 0x112, 0xF060,,, %A_Workingdir%\new 1.txt - Notepad++
Sleep 500
IfWinExist, %A_Workingdir%\new 1.txt - Notepad++
{
    FileAppend, Notepad++ didn't exit for some reason. Test failed.`n, %OUTPUT%
}
IfWinNotExist, %A_Workingdir%\new 1.txt - Notepad++
{
    FileAppend, Notepad++ exited successfully. Test passed.`n, %OUTPUT%
}

Sleep 500
FileRead, Contents, new 1.txt
ERROR_TEST("Opening new 1.txt reported an error", "Opening new 1.txt went fine.")
    If Contents = This is some text in Notepad++
    {
        FileAppend, Text in file matched correctly. Test passed.`n, %OUTPUT%
    }
    else
    {
        FileAppend, Text in file did not match. Test failed.`n, %OUTPUT%
    }

FileDelete, new 1.txt
ERROR_TEST("Deleting new 1.txt reported an error", "Deleting new 1.txt went fine.")

exit 0
