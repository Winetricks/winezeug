;
; AutoHotKey test script for Monopoly Tycoon Demo
;
; Copyright (C) 2009 Aaron Whitehouse
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
testname=Monopoly_Tycoon_Demo
#Include helper_functions
#Include init_test
DOWNLOAD("ftp://ftp.infogrames.net/demos/monopoly_tycoon/mt_demo.EXE", "mt_demo.EXE", "cd2339b0f472e6f34963dcd481f7798add332b91")

;========================
;=== Install the game ===
;========================

; Run the installer
run, mt_demo.EXE
WINDOW_WAIT("Monopoly Tycoon Demo Setup","Welcome to the InstallShield Wizard for Monopoly Tycoon Demo",200)
Send, {ENTER}
Sleep, 100
WINDOW_WAIT("Monopoly Tycoon Demo Setup","Do you accept all the terms of the preceding License Agreement?",20)
Sleep, 300
Send, {ENTER}
Sleep, 500 
WINDOW_WAIT("License agreement","",20)
Send, y
WINDOW_WAIT("Monopoly Tycoon Demo Setup","Setup will install Monopoly Tycoon Demo in the following folder",20)
Sleep, 100
Send, {ENTER}
WINDOW_WAIT("Monopoly Tycoon Demo Setup","Setup will add program icons to the Program Folder listed below",20)
Sleep, 100
Send, {ENTER}
WINDOW_WAIT("Monopoly Tycoon Demo","Would you like to add a Monopoly Tycoon Demo shortcut to the desktop?",300)
Sleep, 100
Send, {ENTER}
Sleep, 100
WINDOW_WAIT("Monopoly Tycoon Demo Setup","Yes, I want to view the README file",20)
Send, {SPACE}{RIGHT}{SPACE}{ENTER}
Sleep, 2000

;========================
;=== Check the files ====
;========================
SetWorkingDir, %A_DesktopCommon%
CHECK_FILE("Monopoly` Tycoon` Demo.lnk")

SetWorkingDir, %A_ProgramsCommon%
CHECK_DIR("Infogrames` Interactive\Monopoly` Tycoon` Demo")
SetWorkingDir, %A_ProgramsCommon%\Infogrames Interactive\Monopoly Tycoon Demo
CHECK_FILE("Monopoly` Tycoon` Demo.lnk")
CHECK_FILE("ReadMe.lnk")
CHECK_FILE("Uninstall` Monopoly` Tycoon` Demo.lnk")

CHECK_DIR("Web` Links")
SetWorkingDir, %A_ProgramsCommon%\Infogrames Interactive\Monopoly Tycoon Demo\Web Links
CHECK_FILE("DeepRed` Games` Ltd.lnk")
CHECK_FILE("Infogrames` Interactive.lnk")
CHECK_FILE("Monopoly` Tycoon.lnk")

SetWorkingDir, %A_ProgramFiles%
CHECK_DIR("Infogrames` Interactive\Monopoly` Tycoon` Demo")
SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo
SHA1("a63cfe57f2aece4ab6c869ddd0b023d4e3d176a4", "DeepRed` Games` Ltd.url")
SHA1("629134b977424440fe1381f009a9de7389d738c0", "dsetup32.dll")
SHA1("9567ee8a12f9645e0e548a8b51ee42f112e136d1", "dsetup.dll")
SHA1("de1d4e042843a372162c6a9c916d212c6d8187c3", "GameSpy.url")
SHA1("984a86eaddb5fe6212abdab938b8308e86cd3ac1", "Infogrames.url")
SHA1("9883f72b3c4ed1e2f720f6fe9dc4ae370f384906", "Monopoly` Tycoon.url")
SHA1("8d2065c34d61bf920eb26d34372f913e3ee4913c", "MTDemo.exe")
SHA1("a69ddeb8a8b7865cfbe5a52dab49ef2fdda27320", "Readme.wri")
CHECK_DIR("language")
CHECK_DIR("max")
CHECK_DIR("parameters")
CHECK_DIR("scripts")

CHECK_DIR("gamedata")
SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\gamedata
SHA1("c4a5996336ccfaa75004a25b2e7027bc4250325a", "infogrames.mpg")
SHA1("86302ff4259de04a3fdd1b124a8df752aae019dd", "loading.bmp")
SHA1("48d4c82370794204e9b0ccd21f76e04da1084b7e", "RoadNodes.bin")
SHA1("f0ff7b98b4ebf6318640abb4553cde58841582b3", "route_smalltable.bin")
SHA1("e86552bd69d7fc8cf3c339bb70e75213f095ac1a", "SUNCOLS.tga")
CHECK_DIR("cursors")
CHECK_DIR("Cut_scenes")
CHECK_DIR("fonts")
CHECK_DIR("roadtextures")
CHECK_DIR("Screens")
CHECK_DIR("sound")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\gamedata\cursors
SHA1("b1e916f9afd1228debf92d3207cf20f9250c0e77", "mono_build_drag.cur")
SHA1("1b5dbdfcb94e812ca712f73a2f8e5378ba4dcdb7", "mono_cursor_block.cur")
SHA1("fbfe75e70c2b04bdf4a3651596236a304054d8dd", "mono_cursor_building.cur")
SHA1("ae98653e8a22dc73a1d7d3a7ad51864ae6c58ef1", "mono_cursor_city.cur")
SHA1("f9b4ecee9c71fba7219b0f98cb55f4ef0e340ad3", "mono_cursor_district.cur")
SHA1("ca326815411805638224da12a8fbbecc32155ab5", "mono_cursor_dropper.cur")
SHA1("86ff8c1c55fc1178d67124e6ff2b0165d3ba1fc5", "mono_cursor_expand.cur")
SHA1("1eb9e8dbe4b8db0c808b6bee99d9c1471803c074", "mono_cursor_grab.cur")
SHA1("02a990bc23511a1c2c6f2980b557f8cb7c652a00", "mono_cursor_hand.cur")
SHA1("dd396e4671a70dae85c1cb12a39b87a3300d43d1", "mono_cursor_people.cur")
SHA1("4232828cd2800c54ec812c903995d5f66dc98805", "mono_cursor_pointer.cur")
SHA1("a490d841732969c68bfcaa3bb4ecf9f22e950492", "mono_cursor_rotate.cur")
SHA1("1c4437e38bf695f1888e9b1fee9955189c932e25", "mono_cursor_track.cur")
SHA1("0436d48aecd4600aac41046bd8469bf177a18777", "mono_cursor_vehicle.cur")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\gamedata\Cut_scenes
SHA1("dfa4e212c48c0906418737b95f121182ace69171", "intro_high.tm")
SHA1("19055fac927b21786dc2060ad11d569673143bcb", "intro_low.tm")
SHA1("6f3ee55946a7a29fadb7dae9581eb429a74fffb4", "intro_medium.tm")
SHA1("f6d44d7ba4976f55097c38732ddcfee2f8a258d0", "lose_cam.tm")
SHA1("140501958c36a8287774bb426697199f020c89cd", "win_cam.tm")
SHA1("ef1fb388ac0fa57820e8ee2fc0a503a1d6c7117b", "win_high.tm")
SHA1("0f9546040f89c20f233083892728b3fa1d380e37", "win_low.tm")
SHA1("248285baaefbec99257a729a9b519abccf6fd07b", "win_medium.tm")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\gamedata\fonts
SHA1("12b9476283de8e6378c31bb1ef5a282e133a68ca", "copperplate18boldp.tab")
SHA1("7e1ee8febe19423627731274ba8709dbe0633fda", "coppgoth23p.tab")
SHA1("a59c6abb650f23ec1c07ba136db7bb9cf3539407", "cust640p.tab")
SHA1("c578dd11bba8afccc5b7441768dc5459e37ca981", "tahoma10bldnoantip.tab")
SHA1("bf71315aac2285c436bea73ac74e43c43f7a32aa", "tahoma11noantip.tab")
SHA1("d6f698edf6d457c9f8fc538abeb6266678430512", "tahoma12bldnoantip.tab")
SHA1("39720595f934f2755456dca14c4562d1584c71d3", "tahoma14bldnoantip.tab")
SHA1("a0ec58013b5b9f51671b18e462c0f1ec5d7075cc", "tahoma15bldnoantip.tab")
SHA1("c2ee1ad4cefc470ee5c3198835512cf1a10a2309", "tahoma16bldnoantip.tab")
SHA1("1f83f2dba4dec881024dc63e2a50344f802f5e4b", "tahoma20bldp.tab")
CHECK_DIR("board")
CHECK_DIR("board\usa")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\gamedata\fonts\board\usa
SHA1("a01bc00d6dbe000532ccd8f5a23ff5a018730ecf", "board.prm")
SHA1("ead80e76720b5f60abe8900dcdbbe9135a3cd7ef", "tycoon.bin")
SHA1("43b0432c3338b0d27b2ccfdfbf50ee73b8df2d45", "tycoon.off")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\gamedata\roadtextures
SHA1("d530b1f18f11a40ce7179199962251750b6e8686", "road_1930_a.tga")
SHA1("f849955a7297b086c7a7200c07f20f265b2ba758", "road_1930_b.tga")
SHA1("d530b1f18f11a40ce7179199962251750b6e8686", "road_1940_a.tga")
SHA1("f849955a7297b086c7a7200c07f20f265b2ba758", "road_1940_b.tga")

SetWorkingDir, %A_ProgramFiles%\Infogrames` Interactive\Monopoly Tycoon Demo\gamedata\Screens
SHA1("ce29ce95e263dd499a601f4955c93beabd936272", "auction.tga")
SHA1("c46187df1faf5cc1c37d21a5ec24392d891b51a1", "DeepRed.tga")
SHA1("b54f42e328933a81c0b3d2d1062161c23a964139", "sales_screen.tga")

SetWorkingDir, %A_ProgramFiles%\Infogrames` Interactive\Monopoly Tycoon Demo\gamedata\sound
CHECK_DIR("high")
CHECK_DIR("music")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\gamedata\sound\high
SHA1("036ac4f78f7eb1662aa4cd4382f6ef77d44ec4db", "ambi_any_altbuild_scaffold.wav")
SHA1("4eaa490f2665f9434e38a8151cfa89057f63992a", "ambi_any_build_hospitalbeep.wav")
SHA1("12ec5a6ca701f8c9f18307bee3cbf525fe3b8eaa", "ambi_any_traff_carengine006.wav")
SHA1("a156977b8f79d60be01bd2d2f9ea4d3e409f8c3a", "ambi_any_traff_trainmotion30.wav")
SHA1("1cd2d46992080e0af4bd3e62540a25caae4e621b", "ambi_any_traff_trainmotion70.wav")
SHA1("d009fe87c6f85f43d6c8d5ec1536c792311447c3", "ambi_day_peop_busycity.wav")
SHA1("46040b6014f03dbe64daa90b7145ba4285741ee8", "ambi_day_traff_busycity.wav")
SHA1("25d2f9551d0f63180815c800de91c508c72817db", "craneend.wav")
SHA1("7d33ff56647f1742db3b13a30a63db3d0902fb95", "cranelift.wav")
SHA1("203f1e80a4f4bb6005d119edfb63d67ce755cb12", "craneloop.wav")
SHA1("479c154e75e1c5f8c8c2c570a38f3d5703836203", "cranestart.wav")
SHA1("714dd2c2500b0e65c50334c3fbe5f0f317365ba4", "dynam_auctioncounter.wav")
SHA1("475aac024a10dc3943ddc72d01968fd1107090f8", "echocrackle2hi.wav")
SHA1("f55ea552d51bfec775bfb4c3910cceafee09911e", "echocrackle2.wav")
SHA1("57999a98c2b95190f3f638e4d68042965d68a09d", "echocracklehi.wav")
SHA1("92b6e4147f967aae9dad41b4478513831c4be999", "echocrackle.wav")
SHA1("36185a3e4fc734338e199f4bd0fddcfe5533f1d4", "echosinglehi.wav")
SHA1("df7b76b6a44149c2b708cc771da6eb0e7228b325", "echosingle.wav")
SHA1("94bf9120a1d841309d9b923007716dcff966f84f", "harpstrum.wav")
SHA1("15bf53bb01c27f88956e65e70a74958fa0dc7ecc", "interface_message.wav")
SHA1("6c48f98ec1a9627aab42475032a60a5cb63cfe99", "launch1.wav")
SHA1("d171777325b9044609768527d95a5e143c93712d", "launch2.wav")
SHA1("aa96b11c0e30dc40affb288be25c6e6d3b0d8fea", "launchwhistle.wav")
SHA1("cb79d4c97908d356678630a35ae862c14ffc633e", "Motor2.wav")
SHA1("efed7ca1617dc5fa6032a356dc9d018c206d9e9c", "negativeboing.wav")
SHA1("fefb3836c82e25de68737c9746f7f2b92d1c7076", "OCEANLIN.WAV")
SHA1("71477bfcf89bea6bff5886eab88cdebf7be5bb16", "OWL6.wav")
SHA1("b562f1a8874ca89a17402c637715124fc0317545", "positivepluck.wav")
SHA1("a08bbe8275fab50e4868451645a23ed6cc391a73", "Presixoclock.wav")
SHA1("5830ac34bbef897be1d29f7ccd1c86709cf3b1bd", "rand_any_altbuild_hammer002.wav")
SHA1("8acf360b77bc2645475166c5cdeb75a10c553017", "rand_any_altbuild_saw.wav")
SHA1("ec14235730907e244d7a8d275aba648ef3802c03", "shipengine.wav")
SHA1("ab30a6ae036d3fa476e2b2dd837c709cf9a7af81", "SHIPHORN.WAV")
SHA1("fa6f36b1fde86c4fc2c54f76bf1e9ae32e645114", "spell.wav")
SHA1("7248ae6627cb84fea31db721d395ca2923b6ef8f", "spot_any_buy.wav")
SHA1("99ebd9efc2453aa7e24fae8718eccff1e020f16f", "spot_any_sell.wav")
SHA1("46cc4ce99857aba7873df209282b62d58da3818a", "spot_any_trainhalt.wav")
SHA1("d4cb97c1ff15fb94d86b06f4bbf671cd9350bf72", "spot_any_train_toot30.wav")
SHA1("40844822f6473a9549492d6c5c827a53064f6db6", "spot_any_train_toot70.wav")
SHA1("5d4c3b1e680a157eab2f19ece39c4e1376e95518", "spot_any_ui_lightclick.wav")
SHA1("11bcbf0803ef7de5a5f333ed3697c545fc467c40", "WAVCRASH2.wav")
SHA1("da677496ad56f948eaaa4dabf41f4a5ff844e5b0", "weaponfired.wav")
CHECK_DIR("auction")
CHECK_DIR("Block_Sounds")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\gamedata\sound\high\auction
SHA1("3cda9d646e1467dd55cb735c26d8aa4fd6d6f69c", "ambi_any_applausehigh.wav")
SHA1("b89af7202dc04b6868770e71d5397bf414cae7df", "auctionmurmer.wav")
SHA1("a694fe2314d7ecc95369468a05936af343ce4f69", "car_bid.wav")
SHA1("179e4480a74476a42f8a4d6440010e01f48195ee", "car_win.wav")
SHA1("4f5cb5eca72691f581cc00e6cce7027223cee12b", "car_withdraw.wav")
SHA1("01f3fd6cd9b0d6204ad5cc792e8caf07b6f4665e", "dog_bid.wav")
SHA1("c4051d75ccfa987048fb6b1f9f862f4675cf41ee", "dog_win.wav")
SHA1("8dc231b7c7f07c23364b0d4bbe1440edc2520202", "dog_withdraw.wav")
SHA1("66398f7214101f5959bfc7cd9a34df62e18f95a6", "dynam_auctioncounter.wav")
SHA1("f0385852db5df3859cb70b32be75f881de2b8fb6", "gun_bid.wav")
SHA1("b7c15047a6f9ca3cd3d8c3f1fae0db824921db02", "gun_win.wav")
SHA1("9d1d95b84ed0a23ecb0a87e1d9132ffc478ae58c", "gun_withdraw.wav")
SHA1("80d26f032ba9c03cac752bbc0db60bf922936dc1", "hat_bid.wav")
SHA1("6a9f68d681878d358fcc22677bf4094ec8e6f623", "hat_win.wav")
SHA1("253817015b53012e9e97d67340afe3efdd4df5df", "hat_withdraw.wav")
SHA1("aa09a4706e150f0fcd1a38ff093fdeb8069f0b71", "horse_bid.wav")
SHA1("463da82b9e238ff58d05ba324ffbe356033efe9e", "horse_win.wav")
SHA1("00cbba36b093817d67d461e576c69e263475b05f", "horse_withdraw.wav")
SHA1("2c9b825c6b5578df2e79b740bf1272f94c535b21", "iron_bid.wav")
SHA1("c1b92b1111429510590e27e4a8ffed0f316bd9ab", "iron_win.wav")
SHA1("a1c24d84677da3e6ffc54eb9f13e3bfe45be9a44", "iron_withdraw.wav")
SHA1("70067663aba338c89a573646046312101dee1d2c", "ship_bid.wav")
SHA1("b654aa10eba846aef7cf7d51f18a16bedd19f459", "ship_win.wav")
SHA1("ce0bd12d0b6cf75d25e880911816ecbf3aa903ac", "ship_withdraw.wav")
SHA1("230366d819aa5296ae8fd40cd5edafbaff737b1d", "shoe_bid.wav")
SHA1("f0690317cdc55de46647ed6f6447c5cd446033fe", "shoe_win.wav")
SHA1("8019e16f5af75ebfcd4da31df3eb0ae8f640469b", "shoe_withdraw.wav")
SHA1("316020757ea533855a9af03b6e568f38c4eae942", "thimble_bid.wav")
SHA1("35d9460d92fc107443f95a269663019a1eba53c9", "thimble_win.wav")
SHA1("0ca1b2027479468c39d96cb6b53513250cf2380b", "thimble_withdraw.wav")
SHA1("b371ced732ea681168862594f6cb729c1ba7c536", "wheelbarrow_bid.wav")
SHA1("3a1be827b5a686aa84f5e47acc5dbda7122e61d9", "wheelbarrow_win.wav")
SHA1("c41dbf401e55c8e1a4601507cb02ccb10e4747bd", "wheelbarrow_withdraw.wav")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\gamedata\sound\high\Block_Sounds
SHA1("9e628ca4cdecb2e7b31b551f5cda7620bd60a715", "ambi_factory_1.wav")
SHA1("9826705c511ebc1ab75347ab785085d282ae2e38", "ambi_park_1.wav")
SHA1("4f36b776d44a2987d2e2d2925c94b46e4eb32de5", "ambi_park_2.wav")
SHA1("71477bfcf89bea6bff5886eab88cdebf7be5bb16", "OWL6.WAV")
SHA1("76be0d1fdb396c8aa4dd67d41f243aa2686cfae4", "SchoolPlayground.wav")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\gamedata\sound\music
SHA1("c0adedeedce3d47d1d5d2ecaf4a192c0bf2da066", "music_30s.wma")
SHA1("63e07c4fbfdd12d64ee846f01e432b63ade499b4", "music_40s.wma")
SHA1("00924c418c69fa5250e16e31d4f11c10835cdf52", "music_intro.wma")
SHA1("78353ae41bf9d6b737f083e30c4becae2382016d", "music_loser.wma")
SHA1("b0931e530d37f5a822bb47d5de5b321bf33c97dc", "music_winner.wma")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\language
CHECK_DIR("usa")
SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\language\usa
SHA1("f7a95bebd87b9d0c0d66c83521e26ebb560e28d4", "Loading.tga")
SHA1("bf6797726c162df7c2afb6a3850adcece9b781d9", "Sales_Screen.tga")
SHA1("115341bec34e37b157d3c1ad886fc33d1ad13dcb", "tycoon.bin")
SHA1("9f6794c167dd4f2660c1fe8723932b535a1a9684", "tycoon.off")
SHA1("6446e009d46fb2c98596b32011f9fa30dee8dc88", "Warning.tga")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\max
SHA1("a4a0b947f25d86b11c9a0f9b926fc2003e56b872", "archive.bin")
SHA1("fed8f4778264bc0e360cfc13928c69a6196747c8", "archive.DIR")
CHECK_DIR("BuildEditorModels")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\max\BuildEditorModels
SHA1("6a664a8f8dbf5f844bdf0c7fe83c16ab9985b245", "BuildFile.dat")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\parameters
SHA1("d4b7aa843f7f4ff744757c826f1451571fc2deaf", "1930.prm")
SHA1("b5bbcb019b51e8ebb5903546c672238bbb3458d3", "1940.prm")
SHA1("761b9adb6ef7e4813a92f4877c8b56e6f4db6d7a", "1950.prm")
SHA1("a8f3f6cde3835a9fcaebe5b7d1b67a0be50ca3e5", "1960.prm")
SHA1("a8f3f6cde3835a9fcaebe5b7d1b67a0be50ca3e5", "1970.prm")
SHA1("a8f3f6cde3835a9fcaebe5b7d1b67a0be50ca3e5", "1980.prm")
SHA1("a8f3f6cde3835a9fcaebe5b7d1b67a0be50ca3e5", "1990.prm")
SHA1("a8f3f6cde3835a9fcaebe5b7d1b67a0be50ca3e5", "2000.prm")
SHA1("02c54fdec279c3bd53406fc9c879beba37f73813", "aiparameter.prm")
SHA1("6580dfadc39a74b8daed5c031146a0fb50d28502", "consumer.prm")
SHA1("da15c6c3b742b254fcd55132b073d94da7a43bf8", "parameter.prm")
SHA1("1546866bae32228c03d9d86d344b2280e5831810", "timetable2.prm")
SHA1("0a1681c0f91fb1ce9e3151a0e286912317693626", "timetable.prm")

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\scripts
SHA1("64e6d9c593b86733d1befca4aa6ee46e62df6060", "DEFAULT\ai.lua")
SHA1("993ec07972f1884de7de15b4b2bfb885f111c07c", "DEFAULT\auctioncamera.lua")
SHA1("c16bdc5e9164ae6913b57779d9ab4a76cc2ac41f", "DEFAULT\blocksettings.lua")
SHA1("da39a3ee5e6b4b0d3255bfef95601890afd80709", "DEFAULT\buildingsettings.lua")
SHA1("7d2ca5041dfab9d080daaf5c3b6d164322458dc6", "DEFAULT\businesssettings.lua")
SHA1("f328adf0dad913542441188ac7ad6fed1221101b", "DEFAULT\commoditysettings.lua")
SHA1("38102d4b81ff3e2966acca78e796b7422516ecea", "DEFAULT\default.lua")
SHA1("44431e69ed11f2dd686c6f6a1381c0fd19993542", "DEFAULT\general.lua")
SHA1("0dfbe7d1d41e1cf0b1d6f39b695cc547bd1698f1", "DEFAULT\hub.lua")
SHA1("316192350409330c7e385c307c36500f1b09b731", "DEFAULT\sound.lua")
SHA1("d4381133d437909e777d682712e03334434acde4", "FLYBY1\hub.lua")
SHA1("da39a3ee5e6b4b0d3255bfef95601890afd80709", "FRONTEND\hub.lua")
SHA1("49ea21e171d5e8a24bd1556dd9c2c747aeadb2e3", "GAMESTART\hub.lua")
SHA1("0929347cd4549bea776d79af9feb1730b3c8b3de", "MAPS\apartmentrim.lua")
SHA1("4ba2278f1e1824ca064e4210c4c951c04affd812", "MAPS\apartments2.lua")
SHA1("d9b6d3059c9a2e086793b66be1e9d4278a4b92d9", "MAPS\cheapbuiltbigmap.lua")
SHA1("3986fa8c4ca9c457304eada5e1c35ed971287253", "MAPS\cheapbuiltmap.lua")
SHA1("4a38a825e3793322b8bc52ddf6ef9e41ac511328", "MAPS\developedmap.lua")
SHA1("bcec005bd6ab993fbd2e88671672735a2a6ad7bf", "MAPS\goodsparsemap.lua")
SHA1("ade5449500fa18bd53e3508d3316ca72dcc12bd3", "MAPS\goodspread.lua")
SHA1("49f8e3adb5235c3f7e24e5ac6d7a92dd6b63ef93", "MAPS\intromap.lua")
SHA1("da99eec8041ea2e10e7ac1373cb4b2e13ca00a4e", "MAPS\mapbuiltup.lua")
SHA1("a8645b9f9813d9686773305b4b9b25ef0d77df30", "MAPS\mapbuiltupmore.lua")
SHA1("48ce2b65313f9b0f9872ec9fff69a5538bc7ace3", "MAPS\monopolymap.lua")
SHA1("a912065d0c72cb1b8b41a673d9a1f439e3d7fa38", "MAPS\parkfiller.lua")
SHA1("31fdd5c5d4e66cc6c950073a55d2742605fe7fed", "MAPS\shoppingmap.lua")
SHA1("f92b22944eb53edf14bf442fff631380f85e5a88", "MAPS\sparsemap.lua")
SHA1("23ce9c05ecba54a3acd236442c7d7b0db7786f45", "MAPS\tempmap.lua")
SHA1("da39a3ee5e6b4b0d3255bfef95601890afd80709", "SCENARIO5\ai.lua")
SHA1("fb2463393dcbc86b77c6449f70ee54157f502065", "SCENARIO5\hub.lua")
SHA1("f59883c79d81121e5313acc2d1f3f450056d8f60", "SCENARIO5\initialpref.lua")
SHA1("370563c7d4f5a3a33f6cdc7f4d09033bc8f440ef", "SCENARIO5\players.lua")
SHA1("c997cc6186f00a1fb3f61081daf6ebfb121853e0", "TUTORIAL10\hub.lua")
SHA1("da14f69e9022a4a538eb2047e5427c7843ab57fd", "TUTORIAL11\hub.lua")
SHA1("00fd220c80f30bcb711bb5149257b2eb0085a242", "TUTORIAL12\ai.lua")
SHA1("4a0f43e1985978f7f140acaba481e5bab9ee4133", "TUTORIAL12\hub.lua")
SHA1("d45ea493b209af4b388fe864a2b4cafe7009e3de", "TUTORIAL12\initialpref.lua")
SHA1("9babdbc175d257f220985979dafe4430f0c668dd", "TUTORIAL12\players.lua")
SHA1("c8ccd6606b9b989a7d09f29f134d7a24da5a2f34", "TUTORIAL1\hub.lua")
SHA1("dab7051942faa03099c7ae4d4cb8f69dbf8f9ef0", "TUTORIAL1\initialpref.lua")
SHA1("338d859deef8d66e8e86d2016083098a97327b03", "TUTORIAL2\hub.lua")
SHA1("00fd220c80f30bcb711bb5149257b2eb0085a242", "TUTORIAL3\ai.lua")
SHA1("d54702504e3f2eb58e4d65f8c83dac65a671b96b", "TUTORIAL3\hub.lua")
SHA1("2cb09c9584c077f62a09b3c6973ea28e69072678", "TUTORIAL3\players.lua")
SHA1("00fd220c80f30bcb711bb5149257b2eb0085a242", "TUTORIAL4\ai.lua")
SHA1("baf0bd98c1f2906cb82307d55a25c0fb98e776c2", "TUTORIAL4\hub.lua")
SHA1("c29863ad9163c6969830ab598f8d99e521acbbf5", "TUTORIAL4\initialpref.lua")
SHA1("9babdbc175d257f220985979dafe4430f0c668dd", "TUTORIAL4\players.lua")
SHA1("ca563c1ddab8cbefa028d387f5dd7b9a6251dd49", "TUTORIAL5\hub.lua")
SHA1("2473efb0224d5dd8fb588c5a4b14705b811c1e00", "TUTORIAL6A\hub.lua")
SHA1("0cf3b0c9cd139182d093816663b64bd07f9ffac3", "TUTORIAL6\hub.lua")
SHA1("843aa67acf0608e4fef88ebae5c1eacfa9489175", "TUTORIAL7\hub.lua")
SHA1("701e5626d0fd99f1784c9974ed413e6aeb33d67f", "TUTORIAL8\hub.lua")
SHA1("fa1fd995b32fc8de10c7e943911125f4cfcd5c8a", "TUTORIAL8\initialpref.lua")
SHA1("23011d15d25d046c54f705d0f532b1a862d4f9d5", "TUTORIAL9\ai.lua")
SHA1("e3e96d3f0e662f8e4dd49b5bf00c72c4bb1d7c2e", "TUTORIAL9\hub.lua")
SHA1("38cd2a85b759a85ce0d6539f2b05623f4d993871", "TUTORIAL9\initialpref.lua")
SHA1("0d9909a9e4aa799376e8aabc7ccaa87b9a77aec5", "TUTORIAL9\players.lua")
CHECK_DIR("DEFAULT")
CHECK_DIR("FLYBY1")
CHECK_DIR("FRONTEND")
CHECK_DIR("GAMESTART")
CHECK_DIR("MAPS")
CHECK_DIR("SCENARIO5")
CHECK_DIR("TUTORIAL1")
CHECK_DIR("TUTORIAL10")
CHECK_DIR("TUTORIAL11")
CHECK_DIR("TUTORIAL12")
CHECK_DIR("TUTORIAL2")
CHECK_DIR("TUTORIAL3")
CHECK_DIR("TUTORIAL4")
CHECK_DIR("TUTORIAL5")
CHECK_DIR("TUTORIAL6")
CHECK_DIR("TUTORIAL6A")
CHECK_DIR("TUTORIAL7")
CHECK_DIR("TUTORIAL8")
CHECK_DIR("TUTORIAL9")

SetWorkingDir, %A_ProgramFiles%\InstallShield Installation Information
CHECK_DIR("{880C8551-B65E-11D5-B777-005004AF2D32}")

SetWorkingDir, %A_ProgramFiles%\InstallShield Installation Information\{880C8551-B65E-11D5-B777-005004AF2D32}
CHECK_FILE("data1.cab")
CHECK_FILE("data1.hdr")
CHECK_FILE("layout.bin")
CHECK_FILE("Setup.exe")
CHECK_FILE("setup.ilg")
CHECK_FILE("Setup.ini")
CHECK_FILE("setup.inx")


;========================
;=== Run the game =======
;========================

SetWorkingDir, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo
run, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\MTDemo.exe
WINDOW_WAIT("Monopoly Tycoon","Monopoly Tycoon Demo v1.0",200)
ControlClick, Configuration, Monopoly Tycoon
WINDOW_WAIT("Configuration","Renderer",20)
ControlClick, Done, Configuration
Sleep, 200
WIN_EXIST_TEST("Configuration")
ControlClick, Exit, Monopoly Tycoon
Sleep, 400
WIN_EXIST_TEST("Monopoly Tycoon")
;run, %A_ProgramFiles%\Infogrames Interactive\Monopoly Tycoon Demo\MTDemo.exe
;WINDOW_WAIT("Monopoly Tycoon","Monopoly Tycoon Demo v1.0",20)
;Sleep, 300
;For some reason, this next line crashes in Windows
;ControlClick, Play, Monopoly Tycoon
;I will add some gameplay tests once this bug is fixed.

;========================
;== Uninstall the game ==
;========================

; Run the uninstaller
run, %A_ProgramFiles%\InstallShield Installation Information\{880C8551-B65E-11D5-B777-005004AF2D32}\Setup.exe
WINDOW_WAIT("Monopoly Tycoon Demo Uninstall","Do you want to uninstall it?",20)
Send, y
WINDOW_WAIT("InstallShield Wizard","Maintenance Complete",20)
Send, {ENTER}

;========================
;== Check uninstalled ===
;========================
SetWorkingDir, %A_DesktopCommon%
CHECK_NOT_FILE("Monopoly` Tycoon` Demo.lnk")

SetWorkingDir, %A_ProgramsCommon%
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\Monopoly` Tycoon` Demo.lnk")
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\ReadMe.lnk")
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\Uninstall` Monopoly` Tycoon` Demo.lnk")
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\Web` Links\DeepRed` Games` Ltd.lnk")
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\Web` Links\Infogrames` Interactive.lnk")
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\Web` Links\Monopoly` Tycoon.lnk")

SetWorkingDir, %A_ProgramFiles%
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\DeepRed` Games` Ltd.url")
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\dsetup32.dll")
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\dsetup.dll")
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\GameSpy.url")
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\Infogrames.url")
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\Monopoly` Tycoon.url")
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\MTDemo.exe")
CHECK_NOT_FILE("Infogrames` Interactive\Monopoly` Tycoon` Demo\Readme.wri")

CLEANUP()
exit 0
