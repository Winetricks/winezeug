#!/bin/sh
# Install prerequisites needed to run Patchwatcher
# Run this as root

# Don't forget normal wine prerequisites!  e.g.
#  wget http://kegel.com/wine/hardy.sh
#  sh hardy.sh

# wine-slave.sh
apt-get install autoconf patch cabextract

# Dashboard2.pl
apt-get install libdate-manip-perl

# get-patches2.pl
apt-get install libmail-pop3client-perl libmime-tools-perl

# libpatchwatcher.sh
apt-get install mailx
