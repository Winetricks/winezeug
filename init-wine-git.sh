#!/bin/sh
# Script to install build-time dependencies for Wine, 
# then download the wine source code
# Copyright 2009 Austin English
# LGPL 2.1

# Determine how to elevate our privileges:
if [ `uname -o` = 'Solaris' ] ; then
    ADMIN_COMMAND=pfexec
elif [ `uname -o` = 'Linux' ] ; then
    ADMIN_COMMAND=sudo
elif [ `uname -o` = 'GNU/Linux' ] ; then
    ADMIN_COMMAND=sudo
else
    echo "Don't know your OS. Exiting."
    exit 1
fi

wget http://winezeug.googlecode.com/svn/trunk/install-wine-deps.sh &&
$ADMIN_COMMAND sh install-wine-deps.sh &&

if [ -x "`which git`" ] && [ ! -d "$HOME/wine-git" ]; then
  git clone "git://source.winehq.org/git/wine.git" $HOME/wine-git
elif [ ! -x "`which git`" ] ; then
  echo "Git not found."
elif [ -d "$HOME/wine-git" ] ; then
  echo "$HOME/wine-git already exists! Not cloning."
else
  echo "Unknown error."
fi

