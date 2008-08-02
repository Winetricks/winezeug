#!/bin/sh
# Simple continuous build for Wine 
# Dan Kegel 2008
#
# Watches both git and wine-patches
# Must do
#    sudo apt-get install libmail-pop3client-perl 
# before running first time.
# Must also set environment variables
#   PATCHWATCHER_USER=user@host.com
#   PATCHWATCHER_HOST=mail.host.com
#   PATCHWATCHER_PASSWORD=userpass 
# before running.

set -e
set -x

# Set this to true on first run and after debugging
initialize=false

TOP=`pwd`
WORK=$TOP/wine-continuous-workdir
if $initialize
then
    rm -rf $WORK
fi
mkdir -p $WORK/mimemail

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
    if ! perl $TOP/get-next-patch.pl > current.patch 
    then
       sleep 60
       return 0
    fi
    echo Processing patch:
    cat current.patch

    rm -rf golden
    mv active golden
    cp -a golden active
    cd active
    if ! patch -p1 < ../current.patch > current.log 2>&1
    then
       echo Patch failed
       # TODO: send negative report to author
    else
       if ! make >> current.log 2>&1
       then
           echo Build failed
           # TODO: send negative report to author
       else
           echo Patch and build succeeded
           # TODO: send positive report to author
       fi
       cat current.log
    fi
    cd $WORK
    rm -rf active
    mv golden active
}

continuous_build()
{
  while sleep 1
  do
     refresh_tree
     use_tree
  done
}

if $initialize
then
    initialize_tree
fi
continuous_build
