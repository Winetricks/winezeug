#!/bin/sh
# Script to install build-time dependencies for Wine.
# If your distro isn't supported here, please add it.
# Home page (until accepted into wine tree): http://winezeug.googlecode.com
# Copyright 2006-2009 Dan Kegel
# Copyright 2009 Austin English
# Please report bugs to http://code.google.com/p/winezeug/issues/list
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

    pkg install SUNWaconf SUNWaudh SUNWbison SUNWcups SUNWflexlex SUNWgcc SUNWgit \
    SUNWGlib SUNWgmake SUNWgnome-common-devel SUNWsane-backend SUNWxorg-headers SUNWxwinc
    exit
fi

if test `uname -s` = 'FreeBSD'
then
    if test ! -w /
    then
        echo "Usage: 'sh $0' as root"
        exit 1
    fi

    pkg_add -r bison cups flex git gsm gstreamer-plugins jpeg lcms libGLU \
    libxslt mpg123 openldap-client sane-backends tiff xorg
    exit
fi

if test `uname -s` = 'NetBSD'
then
    if test ! -w /
    then
        echo "Usage: 'sh $0' as root"
        exit 1
    fi

    pkg_add bison cups flex gsm jpeg lcms libxslt mpg123 openldap-client sane-backends scmgit-base tiff
    exit
fi

if test `uname -s` = 'OpenBSD'
then
    if test ! -w /
    then
        echo "You must run $0 as root"
        exit 1
    fi

    if test ! $PKG_PATH
    then
        echo "\$PKG_PATH is undefined, don't know where to get packages"
        exit 1
    fi

    for pkg in \
        git \
        lcms \
        gsm \
        openldap-client \
        sane-backends \
        gnutls \
        mpg123 \
        jpeg \
        png \
        libxml \
        libxslt \
        bison
    do
        pkg_add $pkg
    done

    if test -d /usr/ports/devel/flex/
    then
        cd /usr/ports/devel/flex
        make
        make install
    else
        echo "Flex wasn't found in ports (or you don't have ports installed)."
        echo "You'll need to build/install flex manually. You need at least version 2.5.33."
        exit 2
    fi

fi

# Regular Linux distros.

if test ! -w /
then
    echo "Usage: sudo sh $0"
    exit 1
fi

#
# Alpine Linux:
alpine_pkgs="\
alsa-lib-dev autoconf automake bison build-base cups-dev flex fontconfig-dev freetype-dev git gnutls-dev gsm-dev \
gst-plugins-base-dev gstreamer-dev jpeg-dev lcms-dev libgphoto2-dev libpng-dev libxcomposite-dev libxcursor-dev \
libxdamage-dev libxinerama-dev libxml2-dev libxrandr-dev libxrender-dev libxslt-dev libxxf86dga-dev mesa-dev \
mpg123-dev ncurses-dev openal-soft-dev openldap-dev openssl-dev paxctl tiff-dev v4l-utils-dev winbind zlib-dev"

#----------------------------------------------------------------------------
# Debian data, common to Debian GNU/kFreeBSD, GNU/Hurd and GNU/Linux:
debian_common_pkgs="\
bison ccache flex fontforge gcc gettext git-core libasound2-dev libaudio-dev libc6-dev libcups2-dev \
libdbus-1-dev libelfg0 libesd0-dev libexif-dev libexpat1-dev libfontconfig1-dev libfreetype6-dev \
libgcrypt11-dev libgif-dev libgl1-mesa-dev libglib2.0-dev libglu1-mesa-dev libgnutls-dev \
libgpg-error-dev libgphoto2-2-dev libgsm1-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev \
libhal-dev libhal-storage-dev libice-dev libjpeg62-dev liblcms1-dev libldap2-dev libmad0 libmad0-dev \
libmng-dev libmpg123-dev libncurses5-dev libodbcinstq1c2 libogg-dev  libopenal-dev libopenal1 \
libpng12-dev libpopt-dev libsane-dev libsm-dev libssl-dev libtasn1-3-dev libtiff4-dev libtiffxx0c2 \
libusb-dev libvorbis-dev libvorbisfile3 libx11-dev libxau-dev libxcomposite-dev libxcursor-dev \
libxdmcp-dev libxext-dev libxfixes-dev libxft-dev libxi-dev libxinerama-dev libxml2-dev libxmu-dev \
libxmu-headers libxrandr-dev libxrender-dev libxslt1-dev libxt-dev libxv-dev libxxf86vm-dev m4 make \
mesa-common-dev unixodbc unixodbc-dev x11proto-composite-dev x11proto-core-dev x11proto-fixes-dev \
x11proto-input-dev x11proto-kb-dev x11proto-randr-dev x11proto-video-dev x11proto-xext-dev \
x11proto-xf86vidmode-dev x11proto-xinerama-dev xtrans-dev zlib1g-dev"

# Linux specific:
debian_linux_pkgs="\
libcapi20-3 libcapi20-dev libieee1284-3-dev linux-libc-dev prelink"

#----------------------------------------------------------------------------
# Ubuntu data
ubuntu_common_pkgs="\
bison ccache cvs flex fontforge gcc gettext git-core libasound2-dev libaudio-dev libc6-dev \
libcapi20-3 libcapi20-dev libdbus-1-dev libesd0-dev libexif-dev \
libexpat1-dev libfontconfig1-dev libfreetype6-dev libgcrypt11-dev libgl1-mesa-dev \
libglib2.0-dev libglu1-mesa-dev libgnutls-dev libgpg-error-dev libgphoto2-2-dev libgsm1-dev libgstreamer0.10-dev \
libgstreamer-plugins-base0.10-dev libhal-dev libice-dev libieee1284-3-dev libjpeg62-dev liblcms1-dev \
libldap2-dev libmad0 libmad0-dev libmng-dev libmpg123-dev libncurses5-dev libodbcinstq1c2 \
libogg-dev  libopenal-dev libopenal1 libpng12-dev libpopt-dev libsane-dev \
libsm-dev libssl-dev libtasn1-3-dev libtiff4-dev libtiffxx0c2 libusb-dev libvorbis-dev \
libvorbisfile3 libx11-dev libxau-dev libxcomposite-dev libxcursor-dev libxdmcp-dev \
libxext-dev libxfixes-dev libxft-dev libxi-dev libxinerama-dev libxml2-dev libxmu-dev \
libxmu-headers libxrandr-dev libxrender-dev libxslt1-dev libxt-dev libxv-dev \
libxxf86vm-dev linux-libc-dev m4 make mesa-common-dev \
unixodbc unixodbc-dev x11proto-composite-dev x11proto-core-dev x11proto-fixes-dev  \
x11proto-input-dev x11proto-kb-dev x11proto-randr-dev x11proto-video-dev x11proto-xext-dev \
x11proto-xf86vidmode-dev x11proto-xinerama-dev xtrans-dev zlib1g-dev \
libelfg0 libgif-dev libhal-storage-dev libjack-dev"

ubuntu_gutsy_pkgs="\
cogito \
libcupsys2-dev \
libfreebob0 \
libglib1.2-dev \
libltdl3 \
libltdl3-dev \
liblzo-dev \
libopencdk8-dev \
odbcinst1debian1 \
render-dev \
x11proto-render-dev \
x-dev \
"

ubuntu_hardy_pkgs="\
libcupsys2-dev \
libfreebob0 \
libglib1.2-dev \
libltdl3 \
libltdl3-dev \
liblzo-dev \
libopencdk10-dev \
odbcinst1debian1 \
x-dev \
"

ubuntu_ibex_pkgs="\
libcups2-dev \
libfreebob0 \
libglib1.2-dev \
liblzo-dev \
libltdl7 \
libltdl7-dev \
odbcinst1debian1 \
x-dev \
"

ubuntu_jaunty_pkgs="\
libcups2-dev \
libfreebob0 \
libglib1.2-dev \
liblzo-dev \
libltdl7 \
libltdl7-dev \
odbcinst1debian1 \
x-dev \
"

ubuntu_karmic_pkgs="\
libcups2-dev \
libfreebob0 \
liblzo2-dev \
libltdl7 \
libltdl7-dev \
libgstreamermm-0.10-dev \
odbcinst1debian1 \
prelink \
x-dev \
"

ubuntu_maverick_pkgs="\
libcups2-dev \
libfreebob0 \
liblzo2-dev \
libltdl7 \
libltdl7-dev \
libgstreamermm-0.10-dev \
odbcinst \
prelink \
"

ubuntu_oneiric_pkgs="\
libcups2-dev \
liblzo2-dev \
libltdl7 \
libltdl7-dev \
libgstreamermm-0.10-dev \
odbcinst \
prelink \
"

ubuntu_64_ibex_usr_lib32_sos="\
libcapi20.so.3 libcrypto.so.0.9.8 libcups.so.2 libfontconfig.so.1 libfreetype.so.6 \
libGL.so.1 libGLU.so.1 libgnutls.so.26 libgphoto2_port.so.0 libgphoto2.so.2 \
libhal.so.1 libjack.so.0 libjpeg.so.62 libmpg123.so.0.2.4 liblcms.so.1 \
libodbc.so.1 libpng12.so.0 libsane.so.1 \
libssl.so.0.9.8 libX11.so.6 libXcomposite.so.1 libXcursor.so.1 libXext.so.6 \
libXinerama.so.1 libXi.so.6 libxml2.so.2 libXrandr.so.2 libXrender.so.1 \
libxslt.so.1 libXxf86vm.so.1 libz.so.1"

ubuntu_64_ibex_lib32_sos="libdbus-1.so.3"

#----------------------------------------------------------------------------
# rpm-based distros

fedora_pkgs="\
alsa-lib-devel audiofile-devel bison cups-devel dbus-devel esound-devel flex \
fontconfig-devel fontforge freeglut-devel freetype-devel gcc giflib-devel git \
gnutls-devel hal-devel isdn4k-utils-devel lcms-devel libgphoto2-devel \
libICE-devel libjpeg-devel libpng-devel libSM-devel libusb-devel libX11-devel \
libXau-devel libXcomposite-devel libXcursor-devel libXext-devel libXi-devel \
libXinerama-devel libxml2-devel libXrandr-devel libXrender-devel \
libxslt-devel libXt-devel libXv-devel libXxf86vm-devel make mesa-libGL-devel \
mesa-libGLU-devel ncurses-devel openldap-devel openssl-devel patch pkgconfig \
prelink samba-winbind sane-backends-devel xorg-x11-proto-devel"

suse_pkgs="\
alsa-devel audiofile bison capi4linux-devel cups-devel desktop-file-utils flex \
fontconfig-devel freeglut-devel freetype2-devel gcc giflib-devel git-core glibc-devel \
gnutls-devel hal-devel jack-devel libgphoto2-devel libjpeg-devel liblcms-devel \
libpng-devel libxml2-devel libxslt-devel make Mesa-devel ncurses-devel openldap2-devel \
openssl-devel pkgconfig unixODBC-devel update-desktop-files xorg-x11-devel zlib-devel"


#----------------------------------------------------------------------------
# Code

# For some reason, Debian/KFreeBSD has this, but it is broken...
case "`uname -s`" in
    *Linux*) lsb_release_path=`which lsb_release 2>/dev/null`;;
esac

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
*Alpine*Linux*) apk add $alpine_pkgs;;
Ubuntu*7.10) apt-get install $ubuntu_common_pkgs $ubuntu_gutsy_pkgs;;
Ubuntu*8.04) apt-get install $ubuntu_common_pkgs $ubuntu_hardy_pkgs;;
Ubuntu*8.10) apt-get install $ubuntu_common_pkgs $ubuntu_ibex_pkgs;;
Linux*Mint*7|Ubuntu*9.04) apt-get install $ubuntu_common_pkgs $ubuntu_jaunty_pkgs;;
Linux*Mint*8|Ubuntu*9.10) apt-get install $ubuntu_common_pkgs $ubuntu_karmic_pkgs;;
Ubuntu*10.04) apt-get install $ubuntu_common_pkgs $ubuntu_karmic_pkgs;;
Ubuntu*10.10) apt-get install $ubuntu_common_pkgs $ubuntu_maverick_pkgs;;
Ubuntu*11.04) apt-get install $ubuntu_common_pkgs $ubuntu_maverick_pkgs;;
Ubuntu*11.10) apt-get install $ubuntu_common_pkgs $ubuntu_oneiric_pkgs;;
Fedora*release*) yum install $fedora_pkgs ;;
SUSE*LINUX*11.1) zypper install $suse_pkgs ;;
Debian*Hurd*) apt-get install $debian_common_pkgs ;;
Debian*Linux*) apt-get install $debian_common_pkgs $debian_linux_pkgs ;;
Debian*6.0.2*) apt-get install $debian_common_pkgs $debian_linux_pkgs ;;
Debian*kFreeBSD*) apt-get install $debian_common_pkgs ;;
*) echo "distro $distro not supported"; exit 1;;
esac

set -x
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
    Linux*Mint*7|Linux*Mint*8|Ubuntu*8.04|Ubuntu*8.10|Ubuntu*9.04|Ubuntu*9.10) 
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
    Fedora*release*)
        yum install alsa-lib-devel.i686 audiofile-devel.i686 cups-devel.i686 dbus-devel.i686 esound-devel.i686 \
            fontconfig-devel.i686 freetype.i686 freetype-devel.i686 giflib-devel.i686 hal-devel.i686 \
            lcms-devel.i686 libICE-devel.i686 libjpeg-devel.i686 libpng-devel.i686 libSM-devel.i686 \
            libusb-devel.i686 libX11-devel.i686 libXau-devel.i686 libXcomposite-devel.i686 \
            libXcursor-devel.i686 libXext-devel.i686 libXi-devel.i686 libXinerama-devel.i686 \
            libxml2-devel.i686 libXrandr-devel.i686  libXrender-devel.i686 libxslt-devel.i686 \
            libXt-devel.i686 libXv-devel.i686 libXxf86vm-devel.i686 mesa-libGL-devel.i686  mesa-libGLU-devel.i686 \
            ncurses-devel.i686 openldap-devel.i686 openssl-devel.i686 zlib-devel.i686 sane-backends-devel.i686 \
            xorg-x11-proto-devel glibc-devel.i686 prelink libstdc++-devel.i686 pulseaudio-libs-devel.i686 \
            gnutls-devel.i686 libgphoto2-devel.i686 openal-soft-devel.i686 isdn4k-utils-devel.i686 \
            gsm-devel.i686 libv4l-devel.i686 cups-devel.i686 libtiff-devel.i686
        ;;
    Ubuntu*10.04|Ubuntu*10.10|Ubuntu*11.04)
        apt-get install ia32-libs lib32asound2-dev lib32ncurses5-dev lib32v4l-dev lib32z1-dev
        ;;
    *)
        echo "I do not know how to install 32 bit libraries for distro $distro yet"
        ;;
    esac
fi
