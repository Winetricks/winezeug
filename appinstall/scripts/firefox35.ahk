;
; AutoHotKey Test Script for Mozilla Firefox 3.5
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

testname=firefox35

#Include helper_functions
#Include init_test

; Download firefox, silently run the installer, sha1sum installed files, run it, verify the window exists, and exit.

DOWNLOAD("http://winezeug.googlecode.com/svn/trunk/appinstall/tools/sha1sum/sha1sum.exe", "sha1sum.exe", "4a578ecd09a2d0c8431bdd8cf3d5c5f3ddcddfc9")
DOWNLOAD("http://releases.mozilla.org/pub/mozilla.org/firefox/releases/3.5/win32/en-US/Firefox%20Setup%203.5.exe", "firefox_3.5.exe", "a9ef21ba8173a5d850b408fc448a7bc889eb68cb")

Runwait, firefox_3.5.exe -ms
ERROR_TEST("Installing Firefox had some error.", "Installing Firefox went okay.")

SetWorkingDir, %A_Programfiles%\Mozilla Firefox
SHA1("9e1ce67152efc161dec76c325837c34c0ace4aac", "AccessibleMarshal.dll")
SHA1("1b06faee1d1085632c4075df652bc38ff79ab602", "application.ini")
SHA1("6018188a2fae3c38b061f12319b68f847c9cf583", "blocklist.xml")
SHA1("990b90ecaa948ff685a1d593708fc9db756ae25b", "browserconfig.properties")
SHA1("a55a6edbdd6e04fd0ccf99d94e201784d82b399d", "crashreporter-override.ini")
SHA1("8e1f450c568b2bfa3535db395076d468810b1265", "crashreporter.exe")
SHA1("316f71823b9f8ed9ec41df81c0b35553270fda96", "crashreporter.ini")
SHA1("52ec84caa5da6b7c752bc6b2c020f8f01406b126", "firefox.exe")
SHA1("e5eae1e859f26645cbc8b7f707da3882991ef364", "freebl3.chk")
SHA1("fe02abcd1f841f599b3520ae315d03d7dd67be39", "freebl3.dll")
CHECK_FILE("install.log")
SHA1("fe32b035ef41aa2177d804bda9f49af957b1da81", "js3250.dll")
SHA1("612b3403f1d60fbcefc18115ccd2eeebcc8d30ee", "LICENSE")
SHA1("fb53a904a324b4f8016f3deb15faa739cfaf91f3", "mozcrt19.dll")
SHA1("4fb3f5e29c23300ab8118d8e75cb86922dcbd4b6", "nspr4.dll")
SHA1("77cfab7e4c1039127491fee1a5237cbcc6cba259", "nss3.dll")
SHA1("97d7909d39802df19d4ece87b10fadd7ebe4766c", "nssckbi.dll")
SHA1("84a7cf2a73dd714783d1fd605dfc75dba08a4ba8", "nssdbm3.dll")
SHA1("b5fa4ee86b1031727cca5af30140eb6342091453", "nssutil3.dll")
SHA1("a9067e6b1e57b01d901f48766fe3266e76180523", "old-homepage-default.properties")
SHA1("a36c3d1ea912cd4f8207fb83a56d6fdfafbfb5a4", "platform.ini")
SHA1("308fea144cadee485e8a6d01c7317db8a9b9ae49", "plc4.dll")
SHA1("aaf61925ce581ecb8008f1d44e9c4313c39e3843", "plds4.dll")
SHA1("d23547d400637473fa163dda95781f1a691b3d85", "README.txt")
SHA1("63201a342cbc2a16a111a7af600ec56e23b3fe02", "smime3.dll")
SHA1("edfae94d90dc45b429e9cee9386b0e03abc6578e", "softokn3.chk")
SHA1("dd0a10050e3bbaf20a6f0942262bd06441fe595a", "softokn3.dll")
SHA1("5b8432bee4aa522c25d71317a1671f880b2146e7", "sqlite3.dll")
SHA1("48a0b0df22ecbe795dcc94cd6c555afef828b3cf", "ssl3.dll")
SHA1("c4ab0139ba70da52253a49b551097bc31c4b99ae", "update.locale")
SHA1("d70dc42d88699c1f51111128b515e5e7ad812456", "updater.exe")
SHA1("46bfb3f6ab5e18758e32e89ad386c29ce7db833c", "updater.ini")
SHA1("e55cffc70e28621785ac9070ee26ebca0dc38eca", "xpcom.dll")
SHA1("f36cb2903363b185a626597ee400f06c83f4e066", "xul.dll")
SHA1("a3534dce13d19dce5b39fdaeecb0a983d6786359", "chrome\browser.jar")
SHA1("7c91819d455eb14062f376218ec8b99bfdc0561c", "chrome\browser.manifest")
SHA1("2b00a18df3ba716eaa38096465212bfd4c29d0fe", "chrome\classic.jar")
SHA1("30f5f5b2753894e11b60e1c1d1997a3f1228c912", "chrome\classic.manifest")
SHA1("ede882f6543a62f439130e2b62c3d39551452a40", "chrome\comm.jar")
SHA1("9b5caa11de37970ccd96adc1e920006f5b6e5f76", "chrome\comm.manifest")
SHA1("97869e876834213e41c7b3057d7b84c2d6515ab3", "chrome\en-US.jar")
SHA1("e331947bb61f3c836102330b54e8583b2ef06c4b", "chrome\en-US.manifest")
SHA1("a931f83304a172a7ae2a729024f2b90cad01ea24", "chrome\pippki.jar")
SHA1("4608e7571ad013787dcd68f23ae385b29c5691d4", "chrome\pippki.manifest")
SHA1("3c5adbf4a48770756ed01322efbbeafd42e56408", "chrome\reporter.jar")
SHA1("34d1c59d246b6b93d29f67acb1693f831962aace", "chrome\reporter.manifest")
SHA1("c216076a952d3caf489874c47dd037dd4c739cae", "chrome\toolkit.jar")
SHA1("2e9b60b626c8303253d71bf55e6fa63dae26bdf3", "chrome\toolkit.manifest")
SHA1("f3d3fa90cc4ea459c7c6196a0e3104520161225d", "components\aboutCertError.js")
SHA1("1a4ebb1aa95863922a4704e560deff66339abe00", "components\aboutPrivateBrowsing.js")
SHA1("2eb1f47e63ca7d94dfd66613a5415907cd9cee58", "components\aboutRights.js")
SHA1("472428ebbdad567bdd7f4ebf8630e34f0ed0e3de", "components\aboutRobots.js")
SHA1("5b1739dc260844ec3d6919ecdefdbe8e7ef4882e", "components\aboutSessionRestore.js")
SHA1("c17be7361f16cfa904f8b49f5d03ed3bc61e00fe", "components\browser.xpt")
SHA1("4ee2db636a0559d288f1e33613b26fa6dc9f2a19", "components\browserdirprovider.dll")
SHA1("c276823c333f7a0eb9ea3593abcded7cb1cdd237", "components\brwsrcmp.dll")
SHA1("60c177d0b6fa89b156f8c6ee2182c2be7335c9cc", "components\FeedConverter.js")
SHA1("c0b442a2ed63e45551d6366ac8ae8537823d09b2", "components\FeedProcessor.js")
SHA1("bf08bdd2ebccd97b1754c14b82bc32426c09a89e", "components\FeedWriter.js")
SHA1("de092acbe9454fb4620bce771e3b2230e50f4f81", "components\fuelApplication.js")
SHA1("f6b74d4a2328d254cb66ec6ecf2c6445cf6a1984", "components\jsconsole-clhandler.js")
SHA1("6a3949a4561df47d5e0ef87f4797441c8fe7b082", "components\NetworkGeolocationProvider.js")
SHA1("c6a6964e3c6382b82255af7187baee70a6c4fb3a", "components\nsAddonRepository.js")
SHA1("d714575a8ebf250c10c69ecb9d17095df49a8e1e", "components\nsBadCertHandler.js")
SHA1("d3b63f25004533c1d8520e64eddcccf9f51970a0", "components\nsBlocklistService.js")
SHA1("075e2488d16d483b091dfa84774ce62b591c841c", "components\nsBrowserContentHandler.js")
SHA1("4b97da9f30e7f61317188cea8b9747cd53a83cb9", "components\nsBrowserGlue.js")
SHA1("e899db7dc7b1d8c6a2d8536d9258ce8e47cbd0f5", "components\nsContentDispatchChooser.js")
SHA1("e405d927793191628e2f44294903d0051a375653", "components\nsContentPrefService.js")
SHA1("ba093052d948a92c6cc33d5e52d3e6b8d84245dc", "components\nsDefaultCLH.js")
SHA1("b8f77bc163b300d9f162a2948f62a686974aafcb", "components\nsDownloadManagerUI.js")
SHA1("391e65b4f36f3519c7998adbde7b45ad256b96ad", "components\nsExtensionManager.js")
SHA1("9ff8b9ecfb889db7e7c99c686e5d33c2261f317c", "components\nsHandlerService.js")
SHA1("8a9a5aa1bbd8b8a7fd694b887f86450756c2f211", "components\nsHelperAppDlg.js")
SHA1("46642fc8214c626697810dad136b4da6cd92ba85", "components\nsLivemarkService.js")
SHA1("0c2ce572ef0a57c5828facd986936ee3821c81c6", "components\nsLoginInfo.js")
SHA1("b604403b912f3eb23d7f82883c6296faa760e428", "components\nsLoginManager.js")
SHA1("0e0a34c4901ab63dd3abae30872ac9b3984a80c6", "components\nsLoginManagerPrompter.js")
SHA1("1ed831673f06bd4eedec2749098393e53bf5c620", "components\nsMicrosummaryService.js")
SHA1("4a54c8fdc443bf422788339c35adcd1349deb336", "components\nsPlacesDBFlush.js")
SHA1("4d65e2c1f5a4d1f1215a6c2a72bbad0dab53a39e", "components\nsPlacesTransactionsService.js")
SHA1("dc9bc5b5fc75a74849af81b9305f56b0c28e6baf", "components\nsPostUpdateWin.js")
SHA1("880125aaae696f62d1e0815db45c929c54e97b47", "components\nsPrivateBrowsingService.js")
SHA1("0a69826656acdf5870943b1822689a70cebbfcf4", "components\nsProxyAutoConfig.js")
SHA1("dda9638658a63bce60e2dc3fc40dd499b8c7ec41", "components\nsSafebrowsingApplication.js")
SHA1("bf4fbac1aac5e30e4ab397d48ab090fd16e6c896", "components\nsSearchService.js")
SHA1("a2ff1d08da12f51f096f04ec8535d721510a6e76", "components\nsSearchSuggestions.js")
SHA1("15013551f8c5d76e6c4262a2e8f2d7552257e308", "components\nsSessionStartup.js")
SHA1("bb335f81171695d32aac06807dcc35d4c64b3b59", "components\nsSessionStore.js")
SHA1("360d08ffb868281428203402a39a5bc66fcc44a2", "components\nsSetDefaultBrowser.js")
SHA1("e0c47fc02d15d71a81146388080e9ccb70f9596f", "components\nsSidebar.js")
SHA1("1c5d4fcdfc5c79b5526cc7bd2540de4c3fb6d10c", "components\nsTaggingService.js")
SHA1("9a38b4a70a05975689dc58b3ff6a969e7661fe2c", "components\nsTryToClose.js")
SHA1("d430e221738c23868ab2406640cf7f7f34a133ee", "components\nsUpdateService.js")
SHA1("773c22b76ae91b6c423de99e6013f1e0e8214ad2", "components\nsUrlClassifierLib.js")
SHA1("85edf44f030146226013392e584ea1b3726678dc", "components\nsUrlClassifierListManager.js")
SHA1("1318cc100b5b9c551ffef06546806f5391ce6b73", "components\nsURLFormatter.js")
SHA1("fd314a65502ae138dab5a8e16b9ff7bd1938db3d", "components\nsWebHandlerApp.js")
SHA1("97e8701968b5fcdfb3564ed55cabcfb595a30ffe", "components\pluginGlue.js")
SHA1("847348a8d58bf2a4d21ec7ce8691db3a7efc5c5c", "components\storage-Legacy.js")
SHA1("65794d82287e098b8ba85de2542865e57b65bcbb", "components\storage-mozStorage.js")
SHA1("ca433b11413c905db0535476d03ade89cd846edc", "components\txEXSLTRegExFunctions.js")
SHA1("a7591cd98fbf732cd0fb33698479c5d38c0bb622", "components\WebContentConverter.js")
SHA1("6b7554f4fb3f1a4f22c1b09f0d1e84eb9438450b", "defaults\autoconfig\platform.js")
SHA1("7fb3a79e959cf46c613599568be8b93bd647652b", "defaults\autoconfig\prefcalls.js")
SHA1("63df52460b0de4571cc08bd6614c722cc6a5cdac", "defaults\pref\channel-prefs.js")
SHA1("09d147916b4461a289194fbb05a605ff110f10c2", "defaults\pref\firefox-branding.js")
SHA1("70cf70c76ba1b171f53f434a5176237bbf6976ff", "defaults\pref\firefox-l10n.js")
SHA1("6738c0847d4d65e447bb29489bfd667925383413", "defaults\pref\firefox.js")
SHA1("894a97792cd350a54921edfa223f8cfe0829d8f6", "defaults\pref\reporter.js")
SHA1("68fbf7ff28aa42a11d28474a1f3535e8f4da3083", "defaults\profile\chrome\userChrome-example.css")
SHA1("257aab5a68752a4de9375aa50809f3faa8b83b26", "defaults\profile\chrome\userContent-example.css")
SHA1("b5365f156c0f11eaaebf08d6d0c64a3bd83745c9", "defaults\profile\bookmarks.html")
SHA1("2d8aee4b5cbfb5e1c08f2a4c9af2110bc1262b11", "defaults\profile\localstore.rdf")
SHA1("ebe84276ea707bf822cf6673064a2c3a6de1d22d", "defaults\profile\mimeTypes.rdf")
SHA1("8d94cf5c736408c218bd7e483cea3357124d232f", "defaults\profile\prefs.js")
SHA1("530f8a33f34f45ed9baae6b260f2f5e284990a78", "dictionaries\en-US.aff")
SHA1("3580430be7a84bd38e51c5d949e26bc514240f98", "dictionaries\en-US.dic")
SHA1("e3cbfa41068643ee38b5ac8053e287391aeade34", "extensions\{972ce4c6-7e08-4474-a285-3208198ce6fd}\install.rdf")
SHA1("96b89118833c46e1a33b8886a6a8a12edeed99bb", "greprefs\all.js")
SHA1("ce27c06c1254b3640c4231e185c2eabed3f04967", "greprefs\security-prefs.js")
SHA1("a0a00b69c3450cb5c66b9cc06fb94841c6963875", "greprefs\xpinstall.js")
SHA1("a792306ac62ba9842ae9f30200d02e6bed60d691", "modules\debug.js")
SHA1("7580cb0663be564544aa32365da1b654da6c32d0", "modules\distribution.js")
SHA1("8a8ca39ede0970d6f27e3dd23ea6dd6e02fcdebd", "modules\DownloadLastDir.jsm")
SHA1("9ec996126c69dd5a4db97640849738b88e4b066a", "modules\DownloadUtils.jsm")
SHA1("15d025e45f158ad3e213e9f3251692bb53dcaf0d", "modules\ISO8601DateUtils.jsm")
SHA1("27df319be62cfbb368569763e690da361fb5bfe1", "modules\Microformats.js")
SHA1("c61df3e94ad7219562d02212728d0ebb6786a821", "modules\PlacesDBUtils.jsm")
SHA1("cb22ebf492f2b73e866b2b96f4816769a0eab75b", "modules\PluralForm.jsm")
SHA1("35d443cef8a759386919f030190b6f8e96ed3873", "modules\SpatialNavigation.js")
SHA1("6c13f3adf020f1270d5897741f21de5d6efc5d4e", "modules\utils.js")
SHA1("0fa012f33bb45972b4eb6661a2c4743959fe36c6", "modules\WindowDraggingUtils.jsm")
SHA1("652fb330a9b6832f80585d22aea81ac851b46220", "modules\XPCOMUtils.jsm")
SHA1("73c6712400b5ab6907ef36cf8b50e2235988202a", "plugins\npnul32.dll")
SHA1("5993adcff475c9bdc0c5b8e4112b7ff05359f1ac", "res\dtd\mathml.dtd")
SHA1("2981b43e6045ff35d34a1027516182447531e0d6", "res\dtd\xhtml11.dtd")
SHA1("532df7db5f7f0e656cb79007edd48fb117836825", "res\entityTables\html40Latin1.properties")
SHA1("59b7eb9d49626e5b6daf102e4cbd70d889df63e3", "res\entityTables\html40Special.properties")
SHA1("374927a30f80ba9ee2a005b6f31182c5b19c0404", "res\entityTables\html40Symbols.properties")
SHA1("177481c2b5ce5618a40d6fc8c6d61e3eea492d76", "res\entityTables\htmlEntityVersions.properties")
SHA1("021cffa78310b691125ef5d93d4e222d67d88555", "res\entityTables\mathml20.properties")
SHA1("9f93809f14f0b16ebe11a1dbc252ec565143c48a", "res\entityTables\transliterate.properties")
SHA1("e528fd1d2e6d795012a79b440d280a30c3d16424", "res\fonts\mathfont.properties")
SHA1("5b7d219dbf27ed68c0a325b6fcc937eb9cb2e8fe", "res\fonts\mathfontStandardSymbolsL.properties")
SHA1("7595a644f04cf66e3b15b757c6a3e09aeeea2b20", "res\fonts\mathfontSTIXNonUnicode.properties")
SHA1("0c9730ca418e52c38f0feacc68bcbd3fb15b87e6", "res\fonts\mathfontSTIXSize1.properties")
SHA1("3af5df2fbaad1dc0a7557996fac7e36ae7fd7764", "res\fonts\mathfontSymbol.properties")
SHA1("32c3ede1c22e9832e65938a0e3cd5f341509cffc", "res\fonts\mathfontUnicode.properties")
SHA1("d0f65d49ecee7e5fa4caa60b112b7a29b052bf0b", "res\html\folder.png")
SHA1("25fb498bffc0956f61e3b2990686d71c03791de5", "res\arrow.gif")
SHA1("dcbc2be2e1a22ba0e534f0ec9714615293e862d4", "res\arrowd.gif")
SHA1("297647fd5da27ebf18462594df1c6fdcf891b28b", "res\broken-image.gif")
SHA1("b424fcf6adc27b70f2db9ffe6d658c15277b8ae6", "res\charsetalias.properties")
SHA1("70e486965f148789a18f8bcb0d36de641ad4bbda", "res\charsetData.properties")
SHA1("f247f8b2d672a04d118dc5567e7aeb43ac593892", "res\contenteditable.css")
SHA1("4537e4a64f58298a1984e7029fe7606e6523c855", "res\designmode.css")
SHA1("8089dec8ecbba3c6af0db3ee8062eeb2668e0891", "res\EditorOverride.css")
SHA1("7c08b0a44f665775360c68f5f621febe5ae3ef74", "res\forms.css")
SHA1("c0b32c82d1580b7c9a6fde4eded9612530d284c9", "res\grabber.gif")
SHA1("e3345fb059be0a17fec9f212f97eace0fe4ae119", "res\hiddenWindow.html")
SHA1("666d4cf98f14f2115e4916f8c7ced78e021cd7bf", "res\html.css")
SHA1("d5b0016a2e0f531b6d693fda89712d84ebe742a2", "res\langGroups.properties")
SHA1("8f7d68f76dce7a54ac92d1160ef486f1a1e0745e", "res\language.properties")
SHA1("b624d81886caa5603172441ef123667f42f482cd", "res\loading-image.gif")
SHA1("238dce2f2e6b2406c3df3065004cc084a241812c", "res\mathml.css")
SHA1("c6fb9248044af1b3096bd6e7e5dcaff4b8f8a984", "res\quirk.css")
SHA1("fd16ae9a91420349e9dc151046448b188d5d179f", "res\svg.css")
SHA1("ae968f5b8766fd895e7097b3a40de7f1c594ba26", "res\table-add-column-after-active.gif")
SHA1("33675f50d10cbf4e7de38068a8c35692aa1de8be", "res\table-add-column-after-hover.gif")
SHA1("bffa6ac37f2d6aa9f030e7b428bc5ca5ca55218b", "res\table-add-column-after.gif")
SHA1("e531178014d8dde3295ecf51e0d4de28c9df7595", "res\table-add-column-before-active.gif")
SHA1("6aa75faf4e9d7ce0c743d9f014d1349822efd64d", "res\table-add-column-before-hover.gif")
SHA1("d07472295c783f52842c727abe8e568bde27bc58", "res\table-add-column-before.gif")
SHA1("8d20541ad474eeff42515e77e81bbd91e5fcbe88", "res\table-add-row-after-active.gif")
SHA1("6cd76a918b50021f3baf7d0f535f1e7588232f52", "res\table-add-row-after-hover.gif")
SHA1("9f55167f4843d25452419ad8b6856c491a7919d5", "res\table-add-row-after.gif")
SHA1("22b4dcaf09843d1a4b73f3aea4de9a988fca277a", "res\table-add-row-before-active.gif")
SHA1("226b23cd455176340c8c72f21481d6fa0ba438c7", "res\table-add-row-before-hover.gif")
SHA1("71d14238f799191d3196f662de97445b2544e56f", "res\table-add-row-before.gif")
SHA1("67c0bbae8ac6dd12cb66621f3539fae6971d91e0", "res\table-remove-column-active.gif")
SHA1("389daf6bcd0ba84a413dce4aff02ae9800eb1061", "res\table-remove-column-hover.gif")
SHA1("891c963cb3c26628dcb18db5653eaca5275b0f9e", "res\table-remove-column.gif")
SHA1("67c0bbae8ac6dd12cb66621f3539fae6971d91e0", "res\table-remove-row-active.gif")
SHA1("389daf6bcd0ba84a413dce4aff02ae9800eb1061", "res\table-remove-row-hover.gif")
SHA1("891c963cb3c26628dcb18db5653eaca5275b0f9e", "res\table-remove-row.gif")
SHA1("0f3128dca6f0c8c57834b9cae8d78fb843e0f275", "res\ua.css")
SHA1("aa6672df3e85b21e59658ce7b259473da5b4c446", "res\viewsource.css")
SHA1("f2e30f66a696051452e49245f1be3f72161ee5e7", "res\wincharset.properties")
SHA1("a611dc3d00c8f5a5f4b3ce92b6781ceaaeaa9dbb", "searchplugins\amazondotcom.xml")
SHA1("ee7e11a0b1a0dcc18b1a89fa66d05e8084576454", "searchplugins\answers.xml")
SHA1("8019ac8832e7be6c7cf343d06b85ea8a712da858", "searchplugins\creativecommons.xml")
SHA1("a68e01aac305746e0f2e2694a7027e61a1980686", "searchplugins\eBay.xml")
SHA1("eb875341fe702d023bb3cf41f5e9400e9b5e907d", "searchplugins\google.xml")
SHA1("226b5808755711b6ea599bbe325f2d14aae58618", "searchplugins\wikipedia.xml")
SHA1("d984ab5b3941ced4c1cfbaa6cef313656b2899cb", "searchplugins\yahoo.xml")
SHA1("dd7c9ff75cc83be82af86ac297a41b995bb2a4b7", "uninstall\helper.exe")
CHECK_FILE("uninstall\uninstall.log")
CHECK_FILE("uninstall\shortcuts_log.ini")
 
Run, firefox.exe
ERROR_TEST("Running Firefox failed.", "Running Firefox went okay.")

TODO_WINDOW_WAIT("Import Wizard", 19089,"", 5)
IfWinExist, Import Wizard
{
ControlSend, MozillaWindowClass18, {Escape}, Import Wizard
ERROR_TEST("Closing Import Wizard reported an error.", "Closing Import Wizard went fine.")
Sleep 500
WIN_EXIST_TEST("Import Wizard")
}

WINDOW_WAIT("Default Browser")
ControlSend, MozillaWindowClass1, {Enter}, Default Browser
Sleep 500
WIN_EXIST_TEST("Default Browser")
ERROR_TEST("Default Browser reported an error.", "Default Browser closed fine.")

WINDOW_WAIT("Welcome to Firefox - Mozilla Firefox")
ERROR_TEST("Firefox's main window reported an error.", "Firefox appears to be running fine.")

CLOSE("Welcome to Firefox - Mozilla Firefox")
WINDOW_WAIT("Quit Firefox")
ControlSend, MozillaWindowClass1, Q, Quit Firefox
ERROR_TEST("Exiting Firefox gave an error.", "Firefox claimed to exit fine.")
Process, Waitclose, firefox.exe, 10 ; Give firefox up to 10 seconds to close
ERROR_TEST("Exiting Firefox process gave an error.", "Firefox process claimed to exit fine.")
WIN_EXIST_TEST("Quit Firefox")
WIN_EXIST_TEST("Welcome to Firefox - Mozilla Firefox")

; Test for bug 14771
Run, firefox.exe
ERROR_TEST("Running Firefox failed.", "Running Firefox went okay.")

WinWait, Default Browser, , 3
    if ErrorLevel
    {
        FileAppend, Default Browser didn't appear. Bug 14771 TODO_FIXED.`n, %OUTPUT%
    }
    Else
    {
        FileAppend, Default Browser appeared. Bug 14771 TODO_FAILED.`n, %OUTPUT%
        IfWinNotActive, Default Browser
            {
            WinActivate, Default Browser
            }
        ControlSend, MozillaWindowClass1, {Enter}, Default Browser
    }

WINDOW_WAIT("Mozilla Firefox Start Page - Mozilla Firefox")
ERROR_TEST("Firefox's main window reported an error.", "Firefox appears to be running fine.")

CLOSE("Mozilla Firefox Start Page - Mozilla Firefox")
Process, Waitclose, firefox.exe, 10 ; Give firefox up to 10 seconds to close
ERROR_TEST("Exiting Firefox process gave an error.", "Firefox process claimed to exit fine.")
WIN_EXIST_TEST("Mozilla Firefox Start Page - Mozilla Firefox")

; Make sure setting default browser manually works:
Runwait, firefox.exe -silent -setDefaultBrowser
ERROR_TEST("Setting default browser to Firefox failed.", "Setting default browser to Firefox went okay.")
Process, Waitclose, firefox.exe, 10 ; Give firefox up to 10 seconds to close
ERROR_TEST("Exiting Firefox process gave an error.", "Firefox process claimed to exit fine.")
Run, start http://www.google.com/
WinWait, Default Browser, , 3
    if ErrorLevel
    {
        FileAppend, Firefox didn't pop up default browser check. Test passed.`n, %OUTPUT%
    }
    Else
    {
        FileAppend, Firefox default browser check appeared. Test failed.`n, %OUTPUT%
        IfWinNotActive, Default Browser
            {
            WinActivate, Default Browser
            }
        ControlSend, MozillaWindowClass1, {Enter}, Default Browser
    }

WINDOW_WAIT("Google - Mozilla Firefox")
ERROR_TEST("Opening google.com reported an error.", "Opening google.com went okay.")

CLOSE("Google - Mozilla Firefox")
Process, Waitclose, firefox.exe, 10 ; Give firefox up to 10 seconds to close
ERROR_TEST("Exiting Firefox process gave an error.", "Firefox process claimed to exit fine.")
WIN_EXIST_TEST("Google - Mozilla Firefox")

; Make sure bug 19220 doesn't regress:
Run, firefox.exe http://www.mozilla.com/en-US/firefox/3.5b99/whatsnew/
ERROR_TEST("Running firefox what's new failed.", "Running firefox what's new went okay.")
WinWait, Default Browser, , 3
    if ErrorLevel
    {
        FileAppend, Firefox didn't pop up default browser check. Test passed.`n, %OUTPUT%
    }
    Else
    {
        FileAppend, Firefox default browser check appeared. Test failed.`n, %OUTPUT%
        IfWinNotActive, Default Browser
            {
            WinActivate, Default Browser
            }
        ControlSend, MozillaWindowClass1, {Enter}, Default Browser
    }
WINDOW_WAIT("Welcome to Firefox 3.5 Preview - Mozilla Firefox")
ERROR_TEST("Opening what's new page reported an error.", "Opening what's new page went okay.")

CLOSE("Welcome to Firefox 3.5 Preview - Mozilla Firefox")
Sleep 500
WIN_EXIST_TEST("Welcome to Firefox 3.5 Preview - Mozilla Firefox")

exit 0
