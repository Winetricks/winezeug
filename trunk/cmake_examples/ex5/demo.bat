call ..\settings.bat
echo assume gtest-1.6.0.zip has been unpacked and renamed to gtest, see demo.sh
mkdir build
cd build
cmake ..
nmake
mymain
