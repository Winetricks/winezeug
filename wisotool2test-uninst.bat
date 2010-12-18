rem Batch file to uninstall everything installed by wisotool2test
rem These commands were found in the Uninstall section of the registry
rem Most of them are not silent, though
rem Once we figure out how to uninstall games silently, perhaps
rem we should add uninstall to wisotool2

"C:\Program Files (x86)\Telltale Games\Strong Bad\Uninstall Episode 5 - 8-Bit Is Enough.exe" /S /KEEPSAVES=0

rem needs silent
C:\Windows\SysWOW64\Macromed\Flash\FlashUtil10i_ActiveX.exe -maintain activex

C:\Windows\SysWOW64\Macromed\Flash\uninstall_plugin.exe

"C:\Program Files (x86)\CMake 2.8\Uninstall.exe"

"C:\Program Files (x86)\Cyanide\GameCenter\uninstall.exe"

rem AOE 3, must gui script or create a setup.iss file and use -f1setup.iss
C:\PROGRA~2\COMMON~1\INSTAL~1\Driver\11\INTEL3~1\IDriver.exe /M{25B25C84-6132-4662-972B-4E4DC1B00C98} 

"C:\Program Files (x86)\InstallShield Installation Information\{6734CA10-8FB8-4C7F-B8C7-75317C617DC5}\setup.exe" -runfromtemp -l0x0409

rem Fable
C:\PROGRA~2\COMMON~1\INSTAL~1\Driver\1050\INTEL3~1\IDriver.exe /M{C3C9EB3D-24FA-4462-B784-0EC6AAFCD2DD} 

rem final fantasy
C:\PROGRA~2\COMMON~1\INSTAL~1\Driver\7\INTEL3~1\IDriver.exe /M{E4D0E11A-CF32-4F7A-8C06-8EC3E2DB2E92} /l1033 

C:\Windows\IsUninst.exe -f"C:\Program Files (x86)\MadOnion.com\3DMark2000\Uninst.isu"

C:\Program Files (x86)\PopCap Games\Plants vs. Zombies\PopUninstall.exe "C:\Program Files (x86)\PopCap Games\Plants vs. Zombies\Install.log"

"C:\Program Files (x86)\Atari\TDU2 Demo\Uninstall\unins000.exe" /SILENT

"C:\Program Files (x86)\Telltale Games\Puzzle Agent\UNINSTALL_Grickle101.exe"

"C:\Program Files (x86)\TmNationsForever\unins000.exe" /SILENT

"C:\Program Files (x86)\Xvid\unins000.exe" /SILENT

rem street fighter iv benchmark
MsiExec.exe /X{FF0AB597-3396-46DB-85CA-9EAEDF5F1590}

rem shockwave
MsiExec.exe /X{ECCA150B-31A5-412E-B8D0-4CB5DDA900D3}

rem quicktime
MsiExec.exe /I{E7004147-2CCA-431C-AA05-2AB166B9785D}

rem applecare support
MsiExec.exe /I{DAEAFD68-BB4A-4507-A241-C8804D2EA66D}

rem rapture 3d
"C:\Program Files (x86)\BRS\unins000.exe" /SILENT

rem futuremark systeminfo
"C:\Program Files (x86)\InstallShield Installation Information\{BEE64C14-BEF1-4610-8A68-A16EAA47B882}\setup.exe" -runfromtemp -l0x0009 -removeonly

rem nfs shift demo
MsiExec.exe /X{BBF0A67B-5DBA-452F-9D2E-6F168BC226E5}

rem physx
MsiExec.exe /X{B83FC356-B7C0-441F-8A4D-D71E088E7974}

rem gfw live redist
MsiExec.exe /X{B578C85A-A84C-4230-A177-C5B2AF565B8C}

rem gfw live
MsiExec.exe /X{B45FABE7-D101-4D99-A671-E16DA40AF7F0}

rem safari
MsiExec.exe /I{AFAC914D-9E83-4A89-8ABE-427521C82CCF}

rem adobe reader
MsiExec.exe /I{AC76BA86-7AD7-1033-7B44-A93000000001}

rem apple software updater
MsiExec.exe /I{6956856F-B6B3-4BE0-BA0B-8F495BE32033}

rem blade kitten demo
MsiExec.exe /I{504EBE89-528F-40AC-ADFA-1C66F94B0A60}



