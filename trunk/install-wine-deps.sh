#!/bin/sh
# Script to install build-time dependencies for Wine.
# If your distro isn't supported here, please add it.
# Home page (until accepted into wine tree): http://winezeug.googlecode.com
# Copyright 2006-2009 Dan Kegel
# Copyright 2009 Austin English
# LGPL

# OpenSolaris stuff...

if test `uname -o` = Solaris
then

    if test ! -w /
    then
        echo "Usage: pfexec sh $0"
        exit 1
    fi

    if test ! `which pkg`
    then
        echo "Only OpenSolaris is supported at this time."    
        exit 1
    fi

    pkg install SUNWaconf SUNWaudh SUNWbison SUNWcups SUNWflexlex SUNWgcc SUNWGlib \
    SUNWgmake SUNWgnome-common-devel SUNWsane-backend SUNWxorg-headers SUNWxwinc
    exit

fi

# Regular Linux distros. Currently just Ubuntu :-/.

if test ! -w /
then
    echo "Usage: sudo sh $0"
    exit 1
fi

#----------------------------------------------------------------------------
# Ubuntu data
ubuntu_common_pkgs="\
bison ccache cvs flex fontforge gcc git-core libasound2-dev libaudio-dev libc6-dev \
libcapi20-3 libcapi20-dev libcupsys2-dev libdbus-1-dev libesd0-dev libexif-dev \
libexpat1-dev libfontconfig1-dev libfreetype6-dev libgcrypt11-dev libgl1-mesa-dev \
libglib1.2-dev libglib2.0-dev libglu1-mesa-dev libgnutls-dev libgpg-error-dev \
libgphoto2-2-dev libgsm1-dev libhal-dev libice-dev libieee1284-3-dev libjpeg62-dev liblcms1-dev \
libldap2-dev libmad0 libmad0-dev libmng-dev libmpg123-dev libncurses5-dev libodbcinstq1c2 \
libogg-dev libpng12-dev libpopt-dev libqt3-headers libqt3-mt libqt3-mt-dev libsane-dev \
libsm-dev libssl-dev libtasn1-3-dev libtiff4-dev libtiffxx0c2 libusb-dev libvorbis-dev \
libvorbisfile3 libx11-dev libxau-dev libxcomposite-dev libxcursor-dev libxdmcp-dev \
libxext-dev libxfixes-dev libxft-dev libxi-dev libxinerama-dev libxml2-dev libxmu-dev \
libxmu-headers libxrandr-dev libxrender-dev libxslt1-dev libxt-dev libxv-dev \
libxxf86vm-dev linux-libc-dev m4 make mesa-common-dev odbcinst1debian1 qt3-dev-tools \
unixodbc unixodbc-dev x11proto-composite-dev x11proto-core-dev x11proto-fixes-dev  \
x11proto-input-dev x11proto-kb-dev x11proto-randr-dev x11proto-video-dev x11proto-xext-dev \
x11proto-xf86vidmode-dev x11proto-xinerama-dev x-dev xtrans-dev zlib1g-dev \
libelfg0 libfreebob0 libgif-dev libhal-storage-dev libjack-dev"

ubuntu_gutsy_pkgs="\
cogito \
libltdl3 \
libltdl3-dev \
liblzo-dev \
libopencdk8-dev \
render-dev \
x11proto-render-dev \
"

ubuntu_hardy_pkgs="\
libltdl3 \
libltdl3-dev \
liblzo-dev \
libopencdk10-dev \
"

ubuntu_ibex_pkgs="\
liblzo-dev \
libltdl7 \
libltdl7-dev \
"

ubuntu_jaunty_pkgs="\
liblzo-dev \
libltdl7 \
libltdl7-dev \
"

ubuntu_karmic_pkgs="\
liblzo2-dev \
libltdl7 \
libltdl7-dev \
"

ubuntu_64_ibex_usr_lib32_sos="\
libcapi20.so.3 libcrypto.so.0.9.8 libcups.so.2 libfontconfig.so.1 libfreetype.so.6 \
libGL.so.1 libGLU.so.1 libgnutls.so.26 libgphoto2_port.so.0 libgphoto2.so.2 \
libhal.so.1 libjack.so.0 libjpeg.so.62 liblcms.so.1 \
libodbc.so.1 libpng12.so.0 libsane.so.1 \
libssl.so.0.9.8 libX11.so.6 libXcomposite.so.1 libXcursor.so.1 libXext.so.6 \
libXinerama.so.1 libXi.so.6 libxml2.so.2 libXrandr.so.2 libXrender.so.1 \
libxslt.so.1 libXxf86vm.so.1 libz.so.1"

ubuntu_64_ibex_lib32_sos="libdbus-1.so.3"

#----------------------------------------------------------------------------
# rpm-based distros

fedora_pkgs="\
bison cups-devel flex fontconfig-devel freeglut-devel freetype-devel gcc git \
gnutls-devel hal-devel isdn4k-utils-devel lcms-devel libgphoto2-devel libjpeg-devel \
libpng-devel libX11-devel libXcomposite-devel libXcursor-devel libXext-devel \
libXi-devel libXinerama-devel libxml2-devel libXrandr-devel libXrender-devel \
libxslt-devel libXt-devel libXxf86vm-devel make ncurses-devel openldap-devel \
openssl-devel patch sane-backends-devel"

suse_pkgs="\
alsa-devel audiofile bison capi4linux-devel cups-devel desktop-file-utils flex \
fontconfig-devel freeglut-devel freetype2-devel gcc giflib-devel git-core glibc-devel \
gnutls-devel hal-devel jack-devel libgphoto2-devel libjpeg-devel liblcms-devel \
libpng-devel libxml2-devel libxslt-devel make Mesa-devel ncurses-devel openldap2-devel \
openssl-devel pkgconfig unixODBC-devel update-desktop-files xorg-x11-devel zlib-devel"


#----------------------------------------------------------------------------
# Code

lsb_release_path=`which lsb_release 2>/dev/null`
if test "$lsb_release_path" != ""
then
  distro=`lsb_release -i -r -s`
elif test -f /etc/issue
  then
    distro=`head -n 1 /etc/issue`
else
  echo "Don't know how to identify your OS."
fi

case $distro in
Ubuntu*7.10) apt-get install $ubuntu_common_pkgs $ubuntu_gutsy_pkgs;;
Ubuntu*8.04) apt-get install $ubuntu_common_pkgs $ubuntu_hardy_pkgs;;
Ubuntu*8.10) apt-get install $ubuntu_common_pkgs $ubuntu_ibex_pkgs;;
Ubuntu*9.04) apt-get install $ubuntu_common_pkgs $ubuntu_jaunty_pkgs;;
Ubuntu*9.10) apt-get install $ubuntu_common_pkgs $ubuntu_karmic_pkgs;;
Fedora*release*10*\(Cambridge\)) yum install $fedora_pkgs ;;
SUSE*LINUX*11.1) zypper install $suse_pkgs ;;
*) echo "distro $distro not supported"; exit 1;;
esac

if test `uname -m` = x86_64
then

# Provide plain old .so names for given libraries
# Usage: linksos dir foo.so.x bar.so.y ...
linksos()
{
    dir=$1
    shift
    for lib
    do
        barename=`echo $lib | sed 's/\.so\..*$/.so/' `
        if test -f $dir/$lib && test ! -f $dir/$barename 
        then
            ln -s $dir/$lib $dir/$barename
        fi
    done
}

    case $distro in
    Ubuntu*8.04|Ubuntu*8.10|Ubuntu*9.04|Ubuntu*9.10) 
        apt-get install ia32-libs lib32asound2-dev lib32z1-dev 
	linksos /usr/lib32 $ubuntu_64_ibex_usr_lib32_sos
	linksos /lib32 $ubuntu_64_ibex_lib32_sos
	# Special cases
	test -f /usr/lib32/libpng.so || ln -s /usr/lib32/libpng12.so /usr/lib32/libpng.so
	test -f /usr/lib32/libldap.so || ln -s /usr/lib32/libldap-2.4.so /usr/lib32/libldap.so
	test -f /usr/lib32/liblber.so || ln -s /usr/lib32/liblber-2.4.so.2 /usr/lib32/liblber.so
	test -f /usr/lib32/libldap_r.so || ln -s /usr/lib32/libldap_r-2.4.so.2 /usr/lib32/libldap_r.so
	# For some reason not installed by default
	apt-get install lib32ncurses5-dev
	;;
    *) 
        echo "I do not know how to install 32 bit libraries for distro $distro yet"
        ;;
    esac
fi
