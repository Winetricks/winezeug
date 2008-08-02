#!/bin/sh
set -e
set -x

TOP=`pwd`
WORK=$TOP/wine-continuous-workdir
rm -rf $WORK
mkdir $WORK

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
    if ! perl $TOP/get_next_patch.pl > current.patch 
    then
       sleep 60
       return 0
    fi

    rm -rf golden
    mv active golden
    cp -a golden active
    cd active
    if ! patch -p1 < ../current.patch > current.log 2>&1
    then
       echo Patch failed
       # negative report to author
    else
       if ! make >> current.log 2>&1
       then
           echo Build failed
           # negative report to author
       else
           echo Patch and build succeeded
           # positive report to author
       fi
    fi
    rm -rf active
    mv golden active
}

continuous_build()
{
  do
     refresh_tree
     use_tree
  done
}

initialize_tree
save_tree
continuous_build
