#!/bin/sh
# Simple continuous build for Wine 
# Dan Kegel 2008
#
# Watches both git and wine-patches
# Must do
#    sudo apt-get install libmail-pop3client-perl 
# before running first time.
# Must also set environment variables to point to a mailbox subscribed to wine-patches
#   PATCHWATCHER_USER=user@host.com
#   PATCHWATCHER_HOST=mail.host.com
#   PATCHWATCHER_PASSWORD=userpass 
# before running.  All messages will slowly be deleted from the mailbox
# as this script runs.

set -e
set -x

# Set this to true on first run and after debugging
initialize=false

TOP=`pwd`
PATCHES=$TOP/patches
WORK=$TOP/wine-continuous-workdir
if $initialize
then
    rm -rf $WORK
fi
mkdir -p $WORK/mimemail $PATCHES
LAST=`ls $TOP/patches | tail -1 | sed 's/\.patch$//;s/\.log$//'`

initialize_tree()
{
    cd $WORK
    git clone git://source.winehq.org/git/wine.git active
    cd active
    ./configure
    make depend
    make -j3
}

refresh_tree()
{
    cd $WORK/active
    git pull > git.log 2>&1
    cat git.log
    if ! grep -q "Already up-to-date." < git.log
    then
       make -j3
    fi
}

use_tree()
{
    cd $WORK
    NEXT=`expr $LAST + 1`
    if ! perl $TOP/get-next-patch.pl > $PATCHES/$NEXT.patch || ! test -s $PATCHES/$NEXT.patch
    then
       echo No patch
       sleep 60
       return 0
    fi
    LAST=$NEXT
    echo Processing patch:
    cat $PATCHES/$NEXT.patch

    rm -rf golden
    mv active golden
    cp -a golden active
    cd active
    if ! patch -p1 < $PATCHES/$NEXT.patch > $PATCHES/$NEXT.log 2>&1
    then
       echo Patch failed
       # TODO: send negative report to author
    else
       if ! make >> $PATCHES/$NEXT.log 2>&1
       then
           echo Build failed
           # TODO: send negative report to author
       else
           echo Patch and build succeeded
           # TODO: send positive report to author
       fi
       cat $PATCHES/$NEXT.log
    fi
    cd $WORK
    rm -rf active
    mv golden active
}

continuous_build()
{
  while sleep 1
  do
     date
     refresh_tree
     use_tree
  done
}

if $initialize
then
    initialize_tree
fi
continuous_build
