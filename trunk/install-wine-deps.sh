#!/bin/sh
# Script to install build-time dependencies for Wine.
# If your distro isn't supported here, please add it.
# Home page (until accepted into wine tree): http://winezeug.googlecode.com
# Copyright 2006-2009 Dan Kegel
# LGPL

set -x

ubuntu_common_pkgs="\
bison ccache cvs flex fontforge gcc git-core libasound2-dev libaudio-dev libc6-dev \
libcapi20-3 libcapi20-dev libcupsys2-dev libdbus-1-dev libesd0-dev libexif-dev \
libexpat1-dev libfontconfig1-dev libfreetype6-dev libgcrypt11-dev libgl1-mesa-dev \
libglib1.2-dev libglib2.0-dev libglu1-mesa-dev libgnutls-dev libgpg-error-dev \
libgphoto2-2-dev libhal-dev libice-dev libieee1284-3-dev libjpeg62-dev liblcms1-dev \
libldap2-dev liblzo-dev libmad0 libmad0-dev libmng-dev libncurses5-dev libodbcinstq1c2 \
libogg-dev libpng12-dev libpopt-dev libqt3-headers libqt3-mt libqt3-mt-dev libsane-dev \
libsm-dev libssl-dev libtasn1-3-dev libtiff4-dev libtiffxx0c2 libusb-dev libvorbis-dev \
libvorbisfile3 libx11-dev libxau-dev libxcomposite-dev libxcursor-dev libxdmcp-dev \
libxext-dev libxfixes-dev libxft-dev libxi-dev libxinerama-dev libxml2-dev libxmu-dev \
libxmu-headers libxrandr-dev libxrender-dev libxslt1-dev libxt-dev libxv-dev \
libxxf86vm-dev linux-libc-dev m4 make mesa-common-dev odbcinst1debian1 qt3-dev-tools \
unixodbc unixodbc-dev x11proto-composite-dev x11proto-core-dev x11proto-fixes-dev  \
x11proto-input-dev x11proto-kb-dev x11proto-randr-dev x11proto-video-dev x11proto-xext-dev \
x11proto-xf86vidmode-dev x11proto-xinerama-dev x-dev xtrans-dev zlib1g-dev"

ubuntu_gutsy_pkgs="\
cogito \
libltdl3 \
libltdl3-dev \
libopencdk8-dev \
render-dev \
x11proto-render-dev \
"

ubuntu_hardy_pkgs="\
git \
libltdl3 \
libltdl3-dev \
libopencdk10-dev \
"

ubuntu_ibex_pkgs="\
git \
libltdl7 \
libltdl7-dev \
"

distro=`lsb_release -i -r -s`
case $distro in
Ubuntu*7.10) apt-get install $ubuntu_common_pkgs $ubuntu_gutsy_pkgs;;
Ubuntu*8.04) apt-get install $ubuntu_common_pkgs $ubuntu_hardy_pkgs;;
Ubuntu*8.10) apt-get install $ubuntu_common_pkgs $ubuntu_ibex_pkgs;;
*) echo distro $distro not supported; exit 1;;
esac
