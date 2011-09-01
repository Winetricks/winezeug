#!/bin/sh
# Script to build gcc-2.95.3 for use with wine
set -e
set -x

system_numcpus() {
    if test "$NUMBER_OF_PROCESSORS"
    then
        echo $NUMBER_OF_PROCESSORS
    elif sysctl -n hw.ncpu 2> /dev/null
    then
        # Mac, freebsd
        :
    else
        # x86 linux
        grep '^processor' /proc/cpuinfo | wc -l
    fi
}

if ! test -d /usr/include/asm
then
    sudo ln -s /usr/include/i386-linux-gnu/asm /usr/include/asm
fi

cat > gcc-2.95.3-collect2.patch <<_EOF_
--- gcc-2.95.3/gcc/collect2.c.old	2011-08-31 19:36:54.000000000 -0700
+++ gcc-2.95.3/gcc/collect2.c	2011-08-31 19:37:27.000000000 -0700
@@ -1759,7 +1759,7 @@
   if (redir)
     {
       /* Open response file.  */
-      redir_handle = open (redir, O_WRONLY | O_TRUNC | O_CREAT);
+      redir_handle = open (redir, O_WRONLY | O_TRUNC | O_CREAT, 0666);
 
       /* Duplicate the stdout and stderr file handles
 	 so they can be restored later.  */
_EOF_

wget -c http://ftp.gnu.org/pub/gnu/gcc/gcc-2.95.3/gcc-core-2.95.3.tar.gz
tar -xzvf gcc-core-2.95.3.tar.gz 
patch -p0 < gcc-2.95.3-collect2.patch
cd gcc-2.95.3/
./configure --enable-languages=c --prefix=/usr/local/gcc-2.95.3
make -j`system_numcpus`
sudo make install
