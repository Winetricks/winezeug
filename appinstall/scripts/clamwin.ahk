;
; AutoHotKey Test Script for Clamwin
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

testname=clamwin

#Include helper_functions
#Include init_test

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
DOWNLOAD("http://downloads.sourceforge.net/clamwin/clamwin-0.95.2-setup.exe", "clamwin-0.95.2-setup.exe", "f6af6e572043e2b3856ae683d0bf95e470de3f3f")

Runwait, clamwin-0.95.2-setup.exe /silent
ERROR_TEST("Installing clamwin had some error.", "Installing clamwin went okay.")

Sleep 500

; Kill the tray process here, apparently it starts itself on its own...
Process, Close, ClamTray.exe
; FIXME: Should use the below code, to shut ClamTray down 'cleanly'.
; This isn't really reliable for some reason. I don't think it's a race. Putting a sleep() above doesn't help.
/*
Process, Exist, ClamTray.exe
pid:=errorlevel
IfWinExist, ahk_pid %pid%
{
    WinClose
    FileAppend, Killed Clamwin tray process. Test passed.`n, %OUTPUT%
}
Else
{
    FileAppend, Clamwin tray process didn't exit or didn't exist for some reason. FIXME: test unreliable. Test failed.`n, %OUTPUT%    
}
*/

; FIXME: Depends on wine's folder structure, so fails on XP...Is there a portable way to get to All Users's folder?
SetWorkingDir, C:\Users\Public\.clamwin\
CHECK_FILE("db\daily.cvd")
CHECK_FILE("db\main.cvd")
CHECK_FILE("db\mirrors.dat")
CHECK_FILE("log\ClamUpdateLog.txt")
CHECK_FILE("quarantine")

SetWorkingDir, %A_AppData%\.clamwin
CHECK_FILE("ClamWin.conf")
CHECK_FILE("ScheduledScans")

Setworkingdir, %A_programfiles%\Clamwin
CHECK_FILE("unins000.dat")
SHA1("b83214557efe0540d390759f0af13bf25916635b", "unins000.exe")
SHA1("236f96c7a07a6c752b5ae74a55955fc3bf2466dd", "bin\clamscan.exe")
SHA1("9d4d07bfbd697d54899131f5be40fbf71b9e5abd", "bin\ClamTray.exe")
CHECK_FILE("bin\ClamWin.conf")
SHA1("5919287a286152cc88721069528ff790d4e05070", "bin\ClamWin.exe")
SHA1("1c8acb1e1ff37fce1bc8bb827064f9ccda013dc3", "bin\ExpShell.dll")
SHA1("cd54a9a787cc102ad41abb65f36c01c565644e73", "bin\freshclam.exe")
SHA1("e841aa46cb897a5fd380467ab8340da6e2a01813", "bin\img\ClamAV.png")
SHA1("088b0b7e8e5b7f09380738a4f8a9fbaa9850043b", "bin\img\clamwin.png")
SHA1("c0fa5202b162eb80dc6e8cc8e1cd028bc910499a", "bin\img\Control.png")
SHA1("966f68f8500e7ccc6dcc99b47386e06d063d17f6", "bin\img\FrameIcon.ico")
SHA1("378bc1e47632289c73733880d784999795b05315", "bin\img\ListScan.png")
SHA1("6efffd831139a547ee495de9893cdca4c12a70a8", "bin\img\netfarm.png")
SHA1("06c5d56a0c5faf8233b2ba15615776c47dab8dc0", "bin\img\Scan.png")
SHA1("edaf0be2260f7da8fede7b5cf91f76034a542d84", "bin\img\ScanMem.png")
SHA1("0dd52864c3785c57915529a767c5ec0674faebd9", "bin\img\Splash.bmp")
SHA1("8ca201beb88e412d7deb5aa6ffedd14d8c6471f1", "bin\img\Title.png")
SHA1("47d98b68bdd594028f70e61d25531310397a7f68", "bin\img\TrayIcon.ico")
SHA1("f475518ab081ef062d053170ce256a203b7e38e7", "bin\img\World.png")
SHA1("bd2376501fbbc57f813aac87541835e09ef9ff31", "bin\libclamav.dll")
SHA1("350fb0a0e5061069bb685d3c086c8c8d46f08351", "bin\libclamunrar.dll")
SHA1("efc7155af3a20f99b85c8f519177f748f37a405f", "bin\libclamunrar_iface.dll")
SHA1("171a62a100f96f64960cee629e3baf577ced1cbb", "bin\manual.chm")
SHA1("277669ab38c20b5a7351073c5bb3bfef6656cc1e", "bin\manual_en.pdf")
SHA1("e27d3f8e1c79f22b9a537c75ef55f6702cc4d656", "bin\Microsoft.VC80.CRT\Microsoft.VC80.CRT.manifest")
SHA1("609b81fbd3acda8c56e2663eda80bfafc9480991", "bin\Microsoft.VC80.CRT\msvcm80.dll")
SHA1("d0a27f553c0fe0e507c7df079485b601d5b592e6", "bin\Microsoft.VC80.CRT\msvcp80.dll")
SHA1("9fd3a7f0522d36c2bf0e64fc510c6eea3603b564", "bin\Microsoft.VC80.CRT\msvcr80.dll")
SHA1("393005b10a53405944a188cd299609aba5c4c512", "bin\pyc.pyd")
SHA1("fd78b2c0d5bc20bcb407557c7c7f16369a4423b1", "bin\python23.dll")
SHA1("1997754c57114772aaf0c932380f14918d92de3c", "bin\sigtool.exe")
SHA1("77c0745af3d3bebe63694ff337e495a7f9790a0d", "bin\w9xpopen.exe")
SHA1("391a6b538124132ab0063f14c3cc48580c57b545", "bin\WClose.exe")
SHA1("36f72ad6b61a90c0965b882c61217197be9e8fa0", "lib\clamwin.zip")
SHA1("1a947afaa685192eed01b1b534787fdfb08ca496", "lib\datetime.pyd")
SHA1("7b1370fbff80cd7e44fa4f1a1eed7e5ae5e5bd9e", "lib\exchange.pyd")
SHA1("e509ae37975f8091538dc2ddae296fb949ba4a05", "lib\exchdapi.pyd")
SHA1("724c8b86313eb0e8f4805c2b7cd9c4add7dd9a66", "lib\gizmosc.pyd")
SHA1("9c735fcedf90dde8ade1b3397d3e25d2e1d97d45", "lib\htmlc.pyd")
SHA1("bcd015da96e7150d68090953d24aa5a23776de43", "lib\mapi.pyd")
SHA1("32e666fa3f3585d2604d100a614f5eab8bb34f76", "lib\mxDateTime.pyd")
SHA1("ff0a42a66e3c2127ddf3f8e87638c1015378d584", "lib\pythoncom23.dll")
SHA1("fcefdba4ec3ec530f221961f589c599f7ecfcef2", "lib\pywintypes23.dll")
SHA1("92836279d5d6fdfc3a4ffec4f660240f11c1e298", "lib\shell.pyd")
SHA1("cb722349b1cbd33ef7ed8050808017b76b2d2577", "lib\unicodedata.pyd")
SHA1("77c0745af3d3bebe63694ff337e495a7f9790a0d", "lib\w9xpopen.exe")
SHA1("260f69cc547a79a290a832d0fdd4559c5db78530", "lib\win32api.pyd")
SHA1("16864214c68911909408afd16b39aaeae1021acb", "lib\win32clipboard.pyd")
SHA1("bfb4aec0d8c08d9dee4d07671225eeb94e41e4a4", "lib\win32event.pyd")
SHA1("5b4b4c6e0475422b731a3e91273e1c84d5ce74de", "lib\win32file.pyd")
SHA1("23cee3b033560b10179749aec6040053b9d1d417", "lib\win32gui.pyd")
SHA1("e7877ccda159fd9558c65f2286f7ad5cea6b2e39", "lib\win32pipe.pyd")
SHA1("12228b17f20afba08eff795145b16a2524532b49", "lib\win32process.pyd")
SHA1("a80eaa91d16801c8961dc33eb930b6c67f90fed9", "lib\win32security.pyd")
SHA1("f7d9e695345352a56c63249d29cdb50d45234e22", "lib\win32trace.pyd")
SHA1("82f5c43ab625f39819b9b4d0aafee676c22eead1", "lib\wxc.pyd")
SHA1("85ea3fa9944759fed1b6a1e204286c7cc98c5ed0", "lib\wxmsw24h.dll")
SHA1("3fd2f296b17059335c54fd88eb988681d1d910f8", "lib\zlib.pyd")
SHA1("793f749c38a6be1dc43f070896a5f58148ca7afd", "lib\_bsddb.pyd")
SHA1("68cd0988b3c96806e886359ab1d141716c04d325", "lib\_ctypes.pyd")
SHA1("46d19972e81abb8ccf5cd48223a5858116ac16fb", "lib\_socket.pyd")
SHA1("31d51ff19d5e80685583887fd23d08ea79d35c76", "lib\_sre.pyd")
SHA1("f04fda91978aa4b7d3593fd7b4f67fb2402249a3", "lib\_ssl.pyd")
SHA1("c0f57bb9f0a4abae5257bf17c865ecc4f8b5e84e", "lib\_winreg.pyd")

Run, bin\ClamWin.exe
ERROR_TEST("Launching Clamwin reported an error", "ClamWin launched fine.")

WINDOW_WAIT("ClamWin Free Antivirus", "Select a folder or a file to scan")
FORCE_CLOSE("ClamWin Free Antivirus")

Sleep 500

IfWinExist, ClamWin Free Antivirus
{
    FileAppend, ClamWin didn't exit for some reason. Test failed.`n, %OUTPUT%
}
IfWinNotExist, ClamWin Free Antivirus
{
    FileAppend, ClamWin exited successfully. Test passed.`n, %OUTPUT%
}

exit 0
