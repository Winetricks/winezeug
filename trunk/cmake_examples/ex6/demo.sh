#!/bin/sh
set -e
set -x
mkdir build
cd build
cmake -G"Eclipse CDT4 - Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug ../demo
echo 'Now start up eclipse and do'
echo 'File / Import / General / Existing Projects Into Workspace, browse to '`pwd`', and click OK'
echo 'Also go to Window -> Preferences -> General -> Workspace'
echo 'and tick both "Refresh using native hooks or polling" and "Refresh on access"'
echo 'so Eclipse will notice when cmake updates the project (when, say, you add a source file in CMakeLists.txt)"'
#make
#./mymain
