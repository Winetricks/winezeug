rem @echo off

SET MOZ_MSVCVERSION=8
SET MOZBUILDDIR=%~dp0
SET MOZILLABUILD=%MOZBUILDDIR%

echo "Mozilla tools directory: %MOZBUILDDIR%"

REM Get MSVC paths
set MSVC6KEY=HKLM\SOFTWARE\Microsoft\VisualStudio\6.0\Setup\Microsoft Visual C++
set MSVC71KEY=HKLM\SOFTWARE\Microsoft\VisualStudio\7.1\Setup\VC
set MSVC8EXPRESSKEY=HKLM\SOFTWARE\Microsoft\VCExpress\8.0\Setup\VC
set MSVC8KEY=HKLM\SOFTWARE\Microsoft\VisualStudio\8.0\Setup\VC
set MSVC9EXPRESSKEY=HKLM\SOFTWARE\Microsoft\VCExpress\9.0\Setup\VC
set MSVC9KEY=HKLM\SOFTWARE\Microsoft\VisualStudio\9.0\Setup\VC
set MSVCEXPROOTKEY=HKLM\SOFTWARE\Microsoft\VCExpress
set MSVCROOTKEY=HKLM\SOFTWARE\Microsoft\VisualStudio
set Path=C:\WINDOWS\System32;C:\WINDOWS;C:\WINDOWS\System32\Wbem
set PSDKDIR=C:\Program Files\Microsoft Platform SDK for Windows Server 2003 R2\
set PSDKVER=5
set SDK2003SP1KEY=HKLM\SOFTWARE\Microsoft\MicrosoftSDK\InstalledSDKs\8F9E5EF3-A9A5-491B-A889-C58EFFECE8B3
set SDK2003SP2KEY=HKLM\SOFTWARE\Microsoft\MicrosoftSDK\InstalledSDKs\D2FF9F89-8AA2-4373-8A31-C838BF4DBBE1
set SDK61KEY=HKLM\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v6.1
set SDK6AKEY=HKLM\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v6.0A
set SDK6KEY=HKLM\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v6.0
set SDK7KEY=HKLM\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v7.0
set SDKDIR=C:\Program Files\Microsoft SDKs\Windows\v6.0A\
set SDKMINORVER=0A
set SDKROOTKEY=HKLM\SOFTWARE\Microsoft\MicrosoftSDK\InstalledSDKs
set SDKVER=6
set VC8EXPRESSDIR=C:\Program Files\Microsoft Visual Studio 8\VC\
set VC8EXPRESSIDEDIR=C:\Program Files\Microsoft Visual Studio 8\Common7\IDE
set WIN64=0
set WINCURVERKEY=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion

REM Use the "new" moztools-static
set MOZ_TOOLS=%MOZBUILDDIR%moztools

rem append moztools to PATH
SET PATH=%PATH%;%MOZ_TOOLS%\bin

    rem Prepend MSVC paths
      rem Might be using a compiler that shipped with an SDK, so manually set paths
      SET PATH=%VC8EXPRESSDIR%\Bin;%VC8EXPRESSIDEDIR%;%PATH%
      SET INCLUDE=%VC8EXPRESSDIR%\Include;%VC8EXPRESSDIR%\Include\Sys;%INCLUDE%
      SET LIB=%VC8EXPRESSDIR%\Lib;%LIB%
    SET USESDK=1
    rem Don't set SDK paths in this block, because blocks are early-evaluated.

    rem Fix problem with VC++Express Edition
        rem SDK Ver.6.0 (Windows Vista SDK) and newer
        rem do not contain ATL header files.
        rem We need to use the Platform SDK's ATL header files.
        SET USEPSDKATL=1

    rem Prepend SDK paths - Don't use the SDK SetEnv.cmd because it pulls in
    rem random VC paths which we don't want.
    rem Add the atlthunk compat library to the end of our LIB
    set PATH=%SDKDIR%\bin;%PATH%
    set LIB=%SDKDIR%\lib;%LIB%;%MOZBUILDDIR%atlthunk_compat;%PSDKDIR%\lib

            set INCLUDE=%SDKDIR%\include;%PSDKDIR%\include\atl;%PSDKDIR%\include;%INCLUDE%

cd "%USERPROFILE%"

"%MOZILLABUILD%\msys\bin\bash" --login -i
