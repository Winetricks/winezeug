;
; AutoHotKey Test Script for 7-Zip
;
; Copyright (C) 2009 Thomas Heckel
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

DOWNLOAD("http://sourceforge.net/projects/sevenzip/files/7-Zip/4.65/7z465.exe/download", "7z465.exe", "c36012e960fa3932cd23f30ac5b0fe722740243a")

; Install 7-Zip
; additionally use /D=%DIR% to choose own installation path. Default will be %A_ProgramFiles%\7-Zip
RunWait, 7z465.exe /S

ERROR_TEST("Installing 7-Zip had some error.", "Installing 7-Zip went okay.")

; START SHA1ING
SetWorkingDir, %A_ProgramFiles%\7-Zip
ERROR_TEST("SET_DIR: setting work directory went wrong", "Setting work directory went okay.")
SHA1("93a00c06f52d7ba737b315bd70f66042b5f3b49f", "7-zip.chm")
SHA1("9d3d9253c2d45c814064c5370b4881ad081d7759", "7-zip.dll")
SHA1("774584ff54b38da5d3b3ee02e30908dacab175c5", "7z.dll")
SHA1("849c937ed5a429448f3f6d1b6519a7d76308d05d", "7z.exe")
SHA1("3313866cdfdfc6406c52034b3685ea0177acca7e", "7z.sfx")
SHA1("6a4504605be967641ee742fe26b1b9601d6da7b9", "7zCon.sfx")
SHA1("676ff0f6b79cc4fe0747638a25d3e70585dced8b", "7zFM.exe")
SHA1("d1049fd05c45f40e73a9adda1cad45d039ef83a5", "7zG.exe")
SHA1("d01e1c0b47ed5a6fc755fe10672c8ffadeaf3ded", "7zip_pad.xml")
SHA1("205bed42a99e28aff738b54bc2ed352198295213", "History.txt")
CHECK_DIR("Lang")
SHA1("35abfe947401966903fd0fae4c5ca1c51c943d5f", "Lang\af.txt")
SHA1("47d6e40d5bb0b90f585c1c0e23a226d90e028bc4", "Lang\ar.txt")
SHA1("7043f13c87b9c9d2def49604932a5af2560b5012", "Lang\ast.txt")
SHA1("edcc09ae3850d5cca7526a3e66fc03b153e86508", "Lang\az.txt")
SHA1("88b2843efe5032637276276a0cc24080e1fbf3c0", "Lang\ba.txt")
SHA1("ee9aff2343fd7127044b6a01ac922c5ac61cb989", "Lang\be.txt")
SHA1("28555695d8283943189e958122c3c4840232acca", "Lang\bg.txt")
SHA1("f8e15eccd3188878c347637c01123ba087366518", "Lang\bn.txt")
SHA1("1d26f9f757ca906c95fbed19b7b713d0e50e4c84", "Lang\br.txt")
SHA1("9ad08979fa6285c8eae6dc6eb4fc2c9323ab7ab7", "Lang\ca.txt")
SHA1("d20c46f0a31ad60f547ee80e7c99b3583d50bf76", "Lang\cs.txt")
SHA1("060985401653409e49114dcbd9b834fb41bc608a", "Lang\cy.txt")
SHA1("a029f18f3e2e06be5cb986c907e3fa40263177b4", "Lang\da.txt")
SHA1("a8464d9e888e91b70022a25b74b882ad3fd3a145", "Lang\de.txt")
SHA1("5941f5dbc604d8cc40b968b52187d8b856d26cae", "Lang\el.txt")
SHA1("c301b7482e74ad00e1896c5bc81dc7f39d3bf470", "Lang\en.ttt")
SHA1("989cc0f1a9e16b860a614ae3e699bc1d7567bcba", "Lang\eo.txt")
SHA1("e0581768bc60f160cb49c450153c89e31d4115ce", "Lang\es.txt")
SHA1("e321179691cbd3cbece5d7e3847c609a36ea2d5e", "Lang\et.txt")
SHA1("e089cc92730d0655c072417256b8a4649d9e5f11", "Lang\eu.txt")
SHA1("154e5c0a75ada93f1fe4ba45ad817a67702ab4f3", "Lang\ext.txt")
SHA1("12cbad4da7ae53478daffdb552d3bb1fde5c7887", "Lang\fa.txt")
SHA1("1a97518dc3fa90f51f04befb0b39c9094b529bc1", "Lang\fi.txt")
SHA1("e3c43e15e479981da24d8b51cb9576b0f45338a6", "Lang\fr.txt")
SHA1("da1f328113d2a5a152ebac1b90b47be648af016d", "Lang\fur.txt")
SHA1("df6b8b9d0653b711f1a4aed8c5ddeb3a2dfc98c9", "Lang\fy.txt")
SHA1("4776c58a6016815afa5c94fc4e257d760e5086f1", "Lang\gl.txt")
SHA1("441eb340d385f8a6ff552a98a35aebc545e1e861", "Lang\he.txt")
SHA1("1c22c0c6d56a895d730bd193c1a604b79c453b2f", "Lang\hr.txt")
SHA1("44581487ac1a52d6f45e6346a5aa0ff8fdde23c2", "Lang\hu.txt")
SHA1("c267b4bb6461a1c8aac7889fde76aef2104da271", "Lang\hy.txt")
SHA1("bf714dd5fe01b467a5b127e79b826ffb30c2c09b", "Lang\id.txt")
SHA1("57688112f93c52eac4c8d2681a2570cbbe355599", "Lang\io.txt")
SHA1("d1f805454cda1a20ae368838f422c1f4af69e037", "Lang\is.txt")
SHA1("d4c8a3ca14a8e2b52751334679f061eec926b2e6", "Lang\it.txt")
SHA1("c21ec04c575f607ff4f19321d658a0359b1cc296", "Lang\ja.txt")
SHA1("45d9ba2a0d3b9af6bde4385a31032a75b1fd00d5", "Lang\ka.txt")
SHA1("4c4b6076e2e7f6e0084ca659948bad7f60561b4e", "Lang\ko.txt")
SHA1("a259ab8c3b3ad8e4d808fbc77a29500cda5af039", "Lang\ku-ckb.txt")
SHA1("a6a601a24f030be967be063bd0a8187f0e4556ca", "Lang\ku.txt")
SHA1("4e629484f13eb965c1617e72f7d3febbbd6ee0c9", "Lang\lt.txt")
SHA1("c6571bed7a511132ef13d52788a1f73325d7f0ae", "Lang\lv.txt")
SHA1("ac9effed42ec4c083382d3d0da391837abf49d56", "Lang\mk.txt")
SHA1("60bf4f15952c71d7286cd10a649b0177092360fb", "Lang\mn.txt")
SHA1("4a1056f4a84f8f12a2d04795926a70e74d5a51ce", "Lang\mr.txt")
SHA1("c5ca1afe62baec9c74e8db46b8fe20aac830b41c", "Lang\ms.txt")
SHA1("213d754009fb71070c67dd6d3d224679a83b27d0", "Lang\nb.txt")
SHA1("6e2d6e8783707c1d34ee92213618fe318d81a00c", "Lang\ne.txt")
SHA1("b61047e6e93b4edc019bf538429850c6db2595d7", "Lang\nl.txt")
SHA1("ebea70e0ebfa37df97591ca3971c4452655e7a67", "Lang\nn.txt")
SHA1("95284eaf44dda67c7b37245c682393d10c203291", "Lang\pa-in.txt")
SHA1("40f9c4197509406396288410df76a39ed88da313", "Lang\pl.txt")
SHA1("d1ab25472975b4c8f617e58d22f024e4a1fd0a2d", "Lang\ps.txt")
SHA1("453ebbebb93a3402a54eaa74bd3218fcdde09e39", "Lang\pt-br.txt")
SHA1("a9459b30b8034194b2c7adae47de1768a6e69941", "Lang\pt.txt")
SHA1("ee8b13d8cce729c52d83b184ef737ef3fca335c3", "Lang\ro.txt")
SHA1("120506011f585e0b645c91e436f46fd1f6571824", "Lang\ru.txt")
SHA1("332cb7b74b57ddec0f000a5c6e6301f40639fe3e", "Lang\si.txt")
SHA1("21b502f79ef9f96ee1b5527f3637166364c40ade", "Lang\sk.txt")
SHA1("e71cb6f2c51ed4519a036c07b46e08f843f82c46", "Lang\sl.txt")
SHA1("0c91a1bf28ff6a9fc442ba086c7578fd32531844", "Lang\sq.txt")
SHA1("30e506aa7e1d8d8b188fb3baa9ce42f6a3e528a2", "Lang\sr-spc.txt")
SHA1("d8898902683ea470448c6f2f17e5d2ea20808952", "Lang\sr-spl.txt")
SHA1("274e7dd08cbde9a72e00ec8ff2733e40749ca1f1", "Lang\sv.txt")
SHA1("78b85b481e127d0af22e7ba1968dac1837b8673f", "Lang\ta.txt")
SHA1("5197d509af4aff96fb12d9579380436c7edddb6d", "Lang\th.txt")
SHA1("a8d3d0b2cf16980f79a07a74893e7b730580aa2f", "Lang\tr.txt")
SHA1("abfe02800adfeb05a34abd09d980bafc144717fa", "Lang\tt.txt")
SHA1("d25d0ae548e9d7f85734eb4cefa6d83d2529c086", "Lang\uk.txt")
SHA1("6fc7d98ae65bb5d3ef1bb2e5dae000e0f6e04e8a", "Lang\uz.txt")
SHA1("bdf71f5bb5dd2f8c9106e8b23d778718e989431b", "Lang\va.txt")
SHA1("3d5eb1dccfdab761deadb590a6739eca9fab0421", "Lang\vi.txt")
SHA1("8e3a32418a1b786ef3dce72396db3c8ec6bb85c5", "Lang\zh-cn.txt")
SHA1("254a200487a7a7ccb1674f8df8165fcd61eb6112", "Lang\zh-tw.txt")
SHA1("e4cac01ef62fa18d5fc98d3c728d435ec05c6305", "License.txt")
SHA1("cba4a6f93c3611d47a343a93f9e95a74d56c04c0", "Uninstall.exe")
SHA1("f4dc0c3b183066767e8ee4b2df64ba2b67287b13", "copying.txt")
SHA1("1a1d0549674ac9739d43a034109185cd92bdf78e", "descript.ion")
SHA1("dcf1c635752a98fad32ed08396d77bf6c2afbf99", "readme.txt")
; END SHA1ING

; #############
; test cases
; #############

;
; TEST
;
TESTNAME("start-close test GUI File Manager")

Run, 7zFM.exe
ERROR_TEST("Running 7-Zip File Manager failed.", "Running 7-Zip File Manager went okay.")
WINDOW_WAIT("ahk_class FM")

Sleep 500 ; Prevent race condition

FORCE_CLOSE("ahk_class FM")
ERROR_TEST("7-Zip File Manager exited with trouble. Test failed.", "7-Zip File Manager exited with no problems. Test passed.")
Sleep 500 ; Prevent race condition
WIN_EXIST_TEST("ahk_class FM")


;
; TEST
;
TESTNAME("Check for status bar text updates. (Bug 17564)")

Run, 7zFM.exe
ERROR_TEST("Running 7-Zip File Manager failed.", "Running 7-Zip File Manager went okay.")
WINDOW_WAIT("ahk_class FM")

Sleep 500 ; Prevent race condition

StatusBarGetText, Statusbar1, 1, ahk_class FM

Send, {Down}
Sleep, 200
StatusBarGetText, Statusbar2, 1, ahk_class FM
If Statusbar2 <> %Statusbar1%
{
    PRINTF("Marking 1 Object has changed status bar text: " Statusbar2 ". Test passed.")
}
Else
{
    PRINTF("Marking 1 Object should change status bar. Test failed.")
}
Send, {Shift Down}{Down}
Sleep, 200
StatusBarGetText, Statusbar3, 1, ahk_class FM
If Statusbar3 <> %Statusbar2%
{
    PRINTF("Marking further object has changed status bar text: " Statusbar3 ". Test passed.")
}
Else
{
    PRINTF("Marking further object should change status bar. Test failed.")
}


FORCE_CLOSE("ahk_class FM")
ERROR_TEST("7-Zip File Manager exited with trouble. Test failed.", "7-Zip File Manager exited with no problems. Test passed.")
Sleep 500 ; Prevent race condition
WIN_EXIST_TEST("ahk_class FM")

TEST_COMPLETED()