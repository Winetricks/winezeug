REM adjust this to match your system

REM You can get the compiler from several places.
REM Uncomment the one you use.  There are also compilers
REM in the Windows 7 Platform SDK, which you need anyway
REM for Windows .lib files, in case you don't need an IDE.
REM Visual C++ 2005 Express 
rem call "c:\Program Files\Microsoft Visual Studio 8\Common7\Tools\vsvars32.bat"

REM Windows 7 Platform SDK
call "c:\Program Files\Microsoft Visual Studio 9.0\VC\bin\vcvars32.bat"
set LIB=c:/Program Files/Microsoft SDKs/Windows/v7.0/Lib;%LIB%
REM On Wine, sadly, vcvars32.bat doesn't work.
PATH %PATH%;C:\Program Files\Microsoft SDKs\Windows\v7.0\Bin
set INCLUDE=C:\Program Files\Microsoft SDKs\Windows\v7.0\Include;%INCLUDE%

REM Third party libraries and tools

REM Tell CMake where Boost lives.
set BOOST_ROOT=c:/Program Files/boost/boost_1_47
REM If you're using the Boost DLLs, put them on the PATH.
PATH C:\Program Files\boost\boost_1_47\lib;%PATH%

rem CMake (if it didn't already put itself on the path)
PATH c:\Program Files\CMake 2.8\bin;%PATH%
