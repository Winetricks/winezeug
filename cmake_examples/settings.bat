REM adjust this to match your system

REM Visual C++ 2005 Express 
rem call "c:\Program Files\Microsoft Visual Studio 8\Common7\Tools\vsvars32.bat"
REM Windows 7 Platform SDK
call "c:\Program Files\Microsoft Visual Studio 9.0\VC\bin\vcvars32.bat"
set LIB=c:/Program Files/Microsoft SDKs/Windows/v7.0/Lib;%LIB%

rem Boosty things
set BOOST_ROOT=c:/Program Files/boost/boost_1_47
rem set LIB=C:/Program Files/boost/boost_1_47/lib;%LIB%
PATH C:\Program Files\boost\boost_1_47\lib;%PATH%

rem CMake (if it didn't already put itself on the path)
PATH c:\Program Files\CMake 2.8\bin;%PATH%
