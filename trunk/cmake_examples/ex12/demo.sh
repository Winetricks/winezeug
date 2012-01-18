#!/bin/sh
set -e
set -x

# Do a 64 bit build.  This assumes you're on a 64 bit machine, and have
# already installed java and c++, e.g. on Ubuntu, that you've done
#   sudo apt-get install gcc g++ openjdk-7-jdk
# or any of the other jdks available.
FORCE_32_BIT=no
export FORCE_32_BIT
rm -rf build64
mkdir build64
cd build64
cmake ..
make
file libCHello.so
LD_LIBRARY_PATH=. java -classpath Hello.jar Hello
cd ..

# Now do a 32 bit build.  There's no nice way to do this; we have
# to point to a particular Java, and jam -m32 flags in by hand
# (see what CMakeLists.txt does with FORCE_32_BIT).
# This assumes you've unpacked
#  http://download.oracle.com/otn-pub/java/jdk/7u2-b13/jdk-7u2-linux-i586.tar.gz
# into /usr/java32, and (on ubuntu, anyway) done
#  sudo apt-get install ia32-libs gcc-multilib g++-multilib
FORCE_32_BIT=yes
JAVA_HOME=/usr/java32/jdk1.7.0_02
export JAVA_HOME
rm -rf build32
mkdir build32
cd build32
cmake ..
make
file libCHello.so
LD_LIBRARY_PATH=. $JAVA_HOME/bin/java -classpath Hello.jar Hello
cd ..

