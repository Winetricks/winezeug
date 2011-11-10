call ..\settings.bat
echo assume gtest-1.6.0.zip has been unpacked and renamed to gtest, see demo.sh

REM repeat this section for Release if you like
mkdir Debug
cd Debug
cmake -G "Visual Studio 9 2008" -DCMAKE_BUILD_TYPE=Debug ../demo

REM start IDE in desired build type directory (Debug or Release)
start Project.sln
