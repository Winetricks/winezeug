#!/bin/bash
#
# Simple script to automate installing new kernels from Ubuntu's kernel testing PPA.
# It will apt-get update, then apt-get dist-upgrade for you. If a new kernel is installed,
# your computer will be rebooted. If not, runs the commands specified.
# Use this to, e.g., automate building your project with the newest kernel, 
# running conformance tests, etc.
#
# To use:
# add the kernel testin ppa: sudo add-apt-repository ppa:kernel-ppa/ppa
# put this script somewhere
# add it to your startup applications. Call it with: sh /path/to/this/script.sh
# put your custom commands at the end, where it says 'custom comamnds here'
# 
# Copyright 2010 Austin English
# LGPL 2.1 License
#
set -exu
{
# Sometimes the network hasn't quite started yet. Sleep for a bit to be safe.
sleep 30

# Notes:
# You'll want to disable passwords for sudo. Yes, it's a security hazard. I use this in a VM,
# not on real hardware...

# Start by updating apt's database:
sudo apt-get update

aptreturn="`sudo apt-get -qqy install linux-image-generic-lts-backport-maverick 2>&1`"

if [ "$aptreturn" ]
   then
        newkernel=1
   else
        newkernel=0 
fi

if [ "$newkernel" = 1 ]
then
    sudo reboot -n
else
    # Run your custom commands here:
    # wget the latest build_script from winezeug, and run it
    # Afterward, shutdown the computer
    export NAME=ae
    export EMAIL=austinenglish
    export MACHINE=lucid-nightkernel 
    rm -rf daily.sh*
    wget http://winezeug.googlecode.com/svn/trunk/build_script/daily.sh
    sh daily.sh --rebase-tree
    rm -rf daily.sh*
    # sudo shutdown now hangs vbox...
    sudo shutdown -P now 
fi
} 2>&1 | tee $HOME/log.txt
