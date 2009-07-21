;
; AutoHotKey Test Script for Quick Media Converter V 3.6.5
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
testname=quickmedia

#Include helper_functions
#Include init_test

; Download Quick Media, unzip it, install it, let it automatically run itself, verify the window exists, close it, then sha1sum files and exit.

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/unzip/unzip.exe", "unzip.exe", "ebfd20263e0a448e857967d4f32a2e85b2728923")
DOWNLOAD("http://www.cocoonsoftware.com/download/INSTALL.zip", "quick_media_3_6_5.zip", "8200cbfcc94910d216932f1bfeb54e22a795c5c4")

Run, unzip.exe -d %APPINSTALL_TEMP% quick_media_3_6_5.zip
ERROR_TEST("Unzipping Quick Media some error.", "Launching Quick Media went okay.")

SetWorkingDir, %APPINSTALL_TEMP%
ERROR_TEST("Setting work directory failed.", "Setting work directory went okay.")

SHA1("5fd7a3cf50daf9dbdf7d7da02c921f3ff570f2d3", "Install.EXE")
Run, Install.EXE
ERROR_TEST("Running installer failed.", "Running installer went okay.")

; Crashes in Wine. See bug 14861.
WinWait, Program Error, The program WDSetup.EXE has encountered a serious problem and needs to close., 10
    if ErrorLevel
    {
        FileAppend, Quick Media Converter didn't crash. Bug 17524 TODO_FIXED.`n, %OUTPUT%
    }
    else
    {
    IfWinNotActive, %windowname%, %windowtext%
        {
        WinActivate, %windowname%, %windowtext%
        }
    FileAppend, K-Meleon crashed. Bug 17524 TODO_FAILED.`n, %OUTPUT%
    ControlClick, Button1, Program Error
    exit 0
    }

WINDOW_WAIT("Player", "Annuler")
ERROR_TEST("Installer window had an error.", "Installer window appears fine.")
ControlClick, Listbox1, Player
ControlSend, E, Player, Annuler
ControlClick, Button2, Player, Annuler

WINDOW_WAIT("Software License Agreement", "I accept the terms in the license agreement")
ERROR_TEST("Installer license window had an error.", "Installer license window appears fine.")
ControlClick, Button2, Software License Agreement, I accept the terms in the license agreement

; Fails on Windows if root drive is not C:\
WINDOW_WAIT("Player - Setup Wizard", "")
ERROR_TEST("Installer path window had an error.", "Installer path window appears fine.")
ControlClick, Button47, Player - Setup Wizard, Cancel ; Cancel is a poor choice of word to detect, but not much else to go on

WINDOW_WAIT("Player - Setup Wizard", "")
ERROR_TEST("Installer window had an error.", "Installer window appears fine.")
ControlClick, Button4, Player - Setup Wizard, &Yes ; &Yes is a poor choice of word to detect, but not much else to go on

WINDOW_WAIT("Player - Setup Wizard", "")
ERROR_TEST("Installer window had an error.", "Installer window appears fine.")
ControlClick, Button47, Player - Setup Wizard, Cancel ; &Yes is a poor choice of word to detect, but not much else to go on

WINDOW_WAIT("Read Me First QMC 3.6.5 Us.txt - Notepad")
FORCE_CLOSE("Read Me First QMC 3.6.5 Us.txt - Notepad")

WINDOW_WAIT("Quick Media Converter   Version : 3.6.5", "CamStudio")
ERROR_TEST("New release window had an error.", "New release window showed no error.")

FORCE_CLOSE("Quick Media Converter   Version : 3.6.5")
ERROR_TEST("Exiting Quick Media gave an error.", "Quick Media claimed to exit fine.")

; Prevent race condition
Sleep 500

IfWinExist, Quick Media Converter   Version : 3.6.5
{
    FileAppend, Quick Media didn't exit for some reason. Test failed.`n, %OUTPUT%
}
IfWinNotExist, Quick Media Converter   Version : 3.6.5
{
FileAppend, Quick Media exited successfully. Test passed.`n, %OUTPUT%
}

; Not going to bother testing shortcut installation. They're spread all over, and not critical at all. We test them elsewhere anyway.
SetWorkingDir, %A_ProgramFiles%\QuickMediaConverter
SHA1("b70fada848262919c290a592d4d8de91a4b0f495","button_green_24x24.png")
SHA1("d211586314b6935b0988f10af8693038619277ae","button_play_16x16.png")
SHA1("b9cf3922e9fe6560a05204c3f6bdc9c2a6af6039","button_play_32x32.png")
SHA1("7999ad5abfb41b9f60c3d0cb1156db7fc008a4f8","button_rec_24x24.png")
SHA1("a685415f42e5640e3c88a7165f9e4cca0fb82794","button_red_16x16.png")
SHA1("a3b95f79214df89e48f22c9387ec53b7a8ab33da","button_red_24x24.png")
SHA1("bb7f216bf3965b9f7729a116487f57b619730725","FeedBack.WDK")
SHA1("08a8e41659ca89b0142d585e8998c3682dc05db4","ffmpeg.exe")
SHA1("d010eae85b68dcd328a41cc715edce372d443ddb","ffmpegaac.exe")
SHA1("a6b4a96c02440ca291f19b89184f40e1e4cfe772","ffplay.exe")
SHA1("72c46930edbb0b02adee426873fc725ddb0a53d9","flvtool2.exe")
SHA1("bb7332228e70fa0a4b3379336d3e3b2d40424187","FORMATVIDEO.txt")
SHA1("6baba4348fb0e5bc795f96c4db298271258dd887","Limitation.WDK")
SHA1("2dd9f959e3cdf606e4ab9200738013155a4e3d12","LimitationApplication.WDK")
SHA1("712f477c77180adfdd0068fbea218f571ec39ecf","MediaInfo.dll")
SHA1("5d0522b387633c0e657d5dd0ffd92f782e9062b9","MediaInfo.exe")
SHA1("e4ce484e415882755c22f68c73154d8bbb72eb5e","MonAppli.ini")
SHA1("dffbcbfbc3b220745ba993f47988df9fd9d4a733","null.dll")
SHA1("9700aab94928a1a009304aaefa2691df9f2537aa","pthreadGC2.dll")
SHA1("d0565e8837900d0eb3ea1722b6bfdacd566c7a21","QMC.exe")
SHA1("4d7c85018aa9859433b00e8f38d83293c88d3d7d","qmc.ini")
SHA1("eaf70cc9e68275e0496a19368be367e985cd42a7","QMC.wx")
SHA1("0e3d8bce8125972d0821bd504370b187e909ef73","SDL.dll")
SHA1("7746a01bf2e6f586c26005c8fb2182622dac95d6","swscale-0.dll")
SHA1("83c80903169a5f9d5e55f91115d478dd35c03659","uninst.inf")
SHA1("05009a63bd64b9b0c2b97df941dafd4708f4b390","WD100COM.DLL")
SHA1("00090b0f52bc5b7756bf03eec2c24e25cda3c2b9","WD100HF.DLL")
SHA1("7ad1c7aaf0949b8b0f5db59f84559cf5726a8525","WD100IMG.DLL")
SHA1("aaed72adef8bd14687a020790d37668712623a8c","WD100MAT.DLL")
SHA1("ce1fc05ffd22a0a37955e084037ac221e96a585a","WD100OBJ.DLL")
SHA1("e60d147da3e7692a4a34b4e0ea9841386254c202","WD100OLE.DLL")
SHA1("83e3190a15c7c2ca926370a3fd12a08ab933c9f3","WD100STD.DLL")
SHA1("3c6aa134ba7f3e4de5f24af30978112e93247b59","WD100VM.DLL")
SHA1("c61b0664d1ac3256fc5aa69628c10e19c08dd300","WD100XML.DLL")
SHA1("a7a803cf3dbcb1a2ef19a7e3fc13c8fc8ca6ffad","WDUNINST.EXE")
SHA1("dc367762f5be1341840bf3f209a8c775f8652612","WDUninst.ini")
SHA1("cbd4ebcb343c7fd4bf932841de2d27b28302f6e7","CamStudio\Camdata.ini")
SHA1("9f2bd1f93a52665ec794cd794f2427d8bd90ea74","CamStudio\CamLayout.ini")
SHA1("39e360753a8c81c7bda72c8482c91844e7336c33","CamStudio\CamShapes.ini")
SHA1("5c50d1c1ca73a7776d163896397edbbf4810195c","CamStudio\CamStudio.ini")
SHA1("da39a3ee5e6b4b0d3255bfef95601890afd80709","CamStudio\CamStudio.Producer.Data.ini")
SHA1("6d3666d9770a2f04063aca6ca0bd5f2bf8fc1fe4","CamStudio\CamStudio.Producer.ini")
SHA1("e2cfe5b4e9ea546e208e4975c85e70c1d2da4cd5","CamStudio\cximage.dll")
SHA1("ea6c84ff0526a538f63421940de374b5c74bee51","CamStudio\default.shapes")
SHA1("0b184ad51ba2a79e85d2288d5fcf8a1ea0481ea4","CamStudio\gpl.txt")
SHA1("b4b9594aa7d6ce964e6b7c689e3134520fcdcd55","CamStudio\hook.dll")
SHA1("514be1b5906309c857d54fc001a5687ebb2f42f8","CamStudio\ntg.bmp")
SHA1("3a6cf415bb3bc14d2e13a5620c937562ef04e10e","CamStudio\Player.exe")
SHA1("adfdfa1fac0dcd12645f8ad97b5b67b83e769167","CamStudio\Playplus.exe")
SHA1("ea2ac0afa795c88246e2191d1fbdf9cce952667d","CamStudio\PlayPlusLANG07.dll")
SHA1("73384349dc6dd5283b0716d93593dc8639cd5e04","CamStudio\Producer.exe")
SHA1("12bf5b93cb98b900428c13d9316399b45260a87b","CamStudio\ProducerLANG07.dll")
SHA1("d4269a7910c4716b450891917ca52af03ffca06b","CamStudio\Recorder.exe")
SHA1("5ea609a3da172f732f115c4ade229e4ba8fc1153","CamStudio\RecorderLANG07.dll")
SHA1("9341a8821cf3e14c4cd51d62ed457890ae81541d","CamStudio\Thumbs.db")
SHA1("351d1cf57ce7472533e9a79f75fd0cc4bdfda9b4","CamStudio\controller\controller.ini")
SHA1("9b55c1dfa65b0b6936f5188c81b42d01ab4a63bf","CamStudio\controller\controller_backup.ini")
SHA1("d7219b9deaca7da0390298001721835794d3858f","CamStudio\controller\leftpiece.bmp")
SHA1("1a9a7dba1a4c8eaaec42982001028cc98f1ba72f","CamStudio\controller\loadnode.bmp")
SHA1("214084be726d9cec15f74f2b1af8441f83b31840","CamStudio\controller\loadpiece.bmp")
SHA1("300ae76faacdad9a33539cb97bb0e4e708ad48ce","CamStudio\controller\pausebutton.bmp")
SHA1("52889bb5d455722d369b08d5cd0c365a10f0405a","CamStudio\controller\pausebutton2.bmp")
SHA1("1801072f6ca9316ca228b4686b377e52c64fd195","CamStudio\controller\playbutton.bmp")
SHA1("8e94b42392c2da82767800baa13cee4b8ff5088f","CamStudio\controller\playbutton2.bmp")
SHA1("884ba2a713da97f1514a83c7f15c191fd60ce3d3","CamStudio\controller\rightpiece.bmp")
SHA1("489060de50b4e0dddb24a1382f01bca1603bb5e3","CamStudio\controller\stopbutton.bmp")
SHA1("179169b22a5324ad65cf27be6ebca7ea69894d0e","CamStudio\controller\stopbutton2.bmp")
SHA1("ffbd4c6aff26e47074edcb4cbaa813b50a12f36f","CamStudio\controller\Thumbs.db")

CLEANUP()
exit 0
