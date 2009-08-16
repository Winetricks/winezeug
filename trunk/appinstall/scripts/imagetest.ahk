;
; AutoHotKey Test Script for gdiplus/imagetest
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

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/unzip/unzip.exe", "unzip.exe", "ebfd20263e0a448e857967d4f32a2e85b2728923")
DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/imagetest/imagetest.exe", "imagetest.exe", "5f1cbf9f60a2a6b73070e20843c7f92b4daf27ad")
DOWNLOAD("http://entropymine.com/jason/bmpsuite/bmpsuite.zip", "bmpsuite.zip", "2e43ec4d8e6f628f71a554c327433914000db7ba")

FileRemoveDir, %APPINSTALL_TEMP%\*, 1
ERROR_TEST("Removing old temp files failed.", "Removed old temp files.")

Runwait, unzip.exe -d %APPINSTALL_TEMP% bmpsuite.zip
ERROR_TEST("Unzipping had some error.", "Unzipping went okay.")

Sleep 500

FileCopy, %APPINSTALL%\imagetest.exe, %APPINSTALL_TEMP%, 1
ERROR_TEST("Copying imagetest.exe had some error.", "Copying imagetest.exe went okay.")

SetWorkingDir, %APPINSTALL_TEMP%
ERROR_TEST("Setting work directory failed.", "Setting work directory went fine.")

; bmpsuite.zip bundles some png's in a separate zip file. Sha1sum that zip & extract it.
SHA1("b42d51a026444a19ed07c2de1460bf01162b21de","bmpsuite-ref.zip")
Runwait, %APPINSTALL%\unzip.exe bmpsuite-ref.zip
ERROR_TEST("Unzipping had some error.", "Unzipping went okay.")

Sleep 500

; Sha1sum everything, then remove unneeded files:
SHA1("e857dcfd2bc00036498b794e30a3352c65e6692b","01bg.png")
SHA1("1fbd3cd639563e70b9c9d63429908ed752ac491f","01bw.png")
SHA1("cdf9f2f4e7cb139ba974a9cd1ac2a0ae38106b03","01p1.png")
SHA1("6af4cc32dd649cebc5916f9b2c6bdd4f8e69d884","04.png")
SHA1("be81b770e870fc99766b830d7f1edaa9a081834d","04p4.png")
SHA1("29528d0243511567bb92478e2cded42456093f96","08.png")
SHA1("e80d5da86a7239a7a0769f98b99c468f240950c5","08p64.png")
SHA1("290ddb99c9ed1d9b42a0caa8f2f5a1d2aa407c1e","08w124.png")
SHA1("8f638bf0d13e4dc64b64d4a509a41f0a7f7cd02b","08w125.png")
SHA1("582d88a6d8c3304f51ae319f990d9e35770ba306","08w126.png")
SHA1("d31ff4d17587f5a01a3ea84d179ece28eaf56479","16bf555.png")
SHA1("50dd81d37457a8c1377545e929726de64fd94961","16bf565.png")
SHA1("f6d26c1d200758720b923c40b41186fbba4db3a0","24.png")
SHA1("0e688357d46770513661a3ffcc6cf4e9d5ed2de8","g01bg.bmp")
SHA1("21ab38376670d9248320433a70ace40b0a8ed2a4","g01bw.bmp")
SHA1("78fc90fad41a85a8cf8d71a086965c66c652219b","g01p1.bmp")
SHA1("6fa767f9829cf5fee5297e3a1c29ae253219e4a1","g01wb.bmp")
SHA1("5e9a9f63c6c8bb1b4f336598a700b5ebfaf4c4d2","g04.bmp")
SHA1("70e204d2ffd444d5ed66304a42986647ab268489","g04p4.bmp")
SHA1("38dc25b3602629f973cbb3ffab208d59610b44d1","g04rle.bmp")
SHA1("8dee02d1761ee2c4d19c42362f98a352b2dcf6ce","g08.bmp")
SHA1("1e8287e8c46a18bc61911aae4ee9bd3bdbedec2f","g08offs.bmp")
SHA1("d20ecaaca35111120d12b957445c9afd8d6bb89b","g08os2.bmp")
SHA1("bf1b5867251070b9ec92367c70cf6aefc16a4050","g08p256.bmp")
SHA1("8dd544bc5e7c218e3a39a908f4cff39d89c0eba8","g08p64.bmp")
SHA1("b9a8f20fd84532af22d10c84657529853f4d38c6","g08pi256.bmp")
SHA1("9fa7106038b87b8a0cd330c67c164e3875e70937","g08pi64.bmp")
SHA1("4ed283d05d326ad5c1e57a128fb53e0e89a66118","g08res11.bmp")
SHA1("7727883ab27ada5dc811db14833f1a0c34ecccbc","g08res21.bmp")
SHA1("49d97a275879f18ebb97f487a997643464fbe5b3","g08res22.bmp")
SHA1("ff4bb02ed4324d937140e8535c661dccdd0571f8","g08rle.bmp")
SHA1("c80b94ad5bc27fcd8e1d88300f7e8fe93b5433af","g08s0.bmp")
SHA1("316f9e8097e105a73d1af0b9c28f3c6265886e45","g08w124.bmp")
SHA1("22048e19172ce7bc12939c648ab8de20ac8bd7f4","g08w125.bmp")
SHA1("bed654bc13b1622badd2cf1ef5c7bacb6fde4de6","g08w126.bmp")
SHA1("709572a9f249760070f983c6bd74031a24ae647a","g16bf555.bmp")
SHA1("36dfb9650ca1629624cc791ede3b2892a5dffb9c","g16bf565.bmp")
SHA1("d5e1f0f04f0701aa997940dcbae583f2a8d1bbf5","g16def555.bmp")
SHA1("ef37f9a239a13930bc27b107c50a1b24339f3a7e","g24.bmp")
SHA1("511a32c9ee36c86695ccdf6ccd3eba19831cb053","g32bf.bmp")
SHA1("77268062ddbb43eaddcc5eeb18765da460d6121a","g32def.bmp")
SHA1("483dfc956b568919b4a5a96ec643c7506b107c36","readme.txt")
SHA1("f23638154f69ada3d351b8f01435ffabfef83378","reference.html")

; We don't need these files.
FileDelete, bmpsuite-ref.zip
ERROR_TEST("Removing bmpsuite-ref.zip failed.", "Removed bmpsuite-ref.zip.")

FileDelete, readme.txt 
ERROR_TEST("Removing readme.txt failed.", "Removed readme.txt.")

FileDelete, reference.html
ERROR_TEST("Removing reference.html failed.", "Removed reference.html.")

; Try loading all files, except imagetest.exe
FileList =
Loop, *.*
    FileList = %FileList%%A_LoopFileName%`n
Sort, FileList
Loop, parse, FileList, `n
{
    if A_LoopField =  ; Ignore blank lines
        continue
    if A_LoopField = imagetest.exe ; loading itself fails, obviously
        continue
    Run, imagetest.exe %A_LoopField%

    ; Basically ERROR_TEST, but without the 'exit'. Apparently the combination of Loop + helper function doesn't work well,
    ; since does not get converted %A_LoopField% to the filename.
    If GetLastError
    {
        FileAppend, Loading %A_LoopField% failed. Test failed.`n, %OUTPUT%
    }
    Else
    {
        FileAppend, Loading %A_LoopField% worked fine. Test passed.`n, %OUTPUT%
    }
    
    WinWait, %A_LoopField%
    if ErrorLevel
    {
        FileAppend, Launching %A_LoopField% failed. Test failed.`n, %OUTPUT%
    }
    else
    {
        FileAppend, Launching %A_LoopField% worked. Test passed.`n, %OUTPUT%
    }

    Sleep 500

    PostMessage, 0x112, 0xF060,,, %A_LoopField%

    Sleep 500
    
    ; Not reporting success here, the log is verbose enough.
    IfWinExist, %A_LoopField%
    {
        FileAppend, %A_LoopField% didn't exit for some reason. Test failed.`n, %OUTPUT%
    }
}

CLEANUP()

TEST_COMPLETED()

exit 0
