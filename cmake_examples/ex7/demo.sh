#!/bin/sh
set -e
set -x

SRC=`dirname $0`
SRC=`cd $SRC; pwd`

mkdir build
cd build

# Generate null projects for each source directory by hand
# rather than asking the cdt generator to do it, since 
# it can't handle more than one
for dir in demo libsrc
do
    sed "s/PROJNAME/_$dir/" < ../skeleton.project > ../$dir/.project
done

cmake -G"Eclipse CDT4 - Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug ../demo

echo "File / Import / General / Existing PROJECTS Into Workspace, then browse to"
echo "and select $SRC (the parent directory)."
echo "You should see projects _demo and _libsrc, and the Team menu on each"
echo "should show that it's connected to svn."
echo ""
echo "Also, if you haven't yet, go to Window -> Preferences -> General -> Workspace"
echo 'and tick both "Refresh using native hooks or polling" and "Refresh on access"'
echo 'so Eclipse will notice when cmake updates the project (when, say, you add a source file in CMakeLists.txt)"'
#make
#./mymain
