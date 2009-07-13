#!/bin/sh
# Script to install build-time dependencies for Wine.
# Copyright 2009 Austin English
# Based off of Darwine ( http://www.kronenberg.org/darwine/), by Mike Kronenberg.
# Used with permission
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
#

# Notes:
# Currently, only supports OS X. Eventually, may support Net/OpenBSD, or other
# OS's that don't have a nice packaging system builtin (or doesn't have the packages needed).

# TODO:
# Curl doesn't seem to want to resume downloads for some reason. Each time the script is run
# all old files are deleted, which is a bit wasteful. But since you should only need to run
# the script once, it's not that big of a deal.
#
# Add libhal/capi support.

if [ ! `uname -s` = 'Darwin' ]
then
    echo "This build script currently only supports Mac OS X"
    exit 1
fi

set -x
BUILD_DIR="$HOME/.winedeps"
CACHE="$HOME/.winedepcache"
TEMP="$HOME"/.winedeptemp
OLDDIR="`pwd`"
rm -rf $TEMP $BUILD_DIR $CACHE
mkdir -p $TEMP $BUILD_DIR $CACHE
#----------------------------------------------
# Helper functions

# From winetricks:

die() {
  echo "$@"
  exit 1
}

try() {
    echo Executing "$@"
    "$@"
    status=$?
    if test $status -ne 0
    then
        die "Note: command '$@' returned status $status.  Aborting."
    fi
}


verify_sha1sum() {
    if [ -x "`which sha1sum`" ] ; then
        SHA1SUM="sha1sum"
    elif [ -x "`which openssl`" ] ; then
        SHA1SUM="openssl dgst -sha1"
    else
        die "Sha1sum not available!"
    fi    

    WANTSUM=$1
    FILE=$2

    GOTSUM=`$SHA1SUM < $FILE | sed 's/ .*//'`
    if [ "$GOTSUM"x != "$WANTSUM"x ]
    then
       die "sha1sum mismatch!  Rename $FILE and try again."
    fi
}

# Bit of a misnomer...actually downloads a file to $CACHE, sha1sum's it, then extracts it to $TEMP/$NAME.
# To handle all this, you need to supply a few things. Example function:
# download http://pkgconfig.freedesktop.org/releases/pkg-config-0.23.tar.gz SHA1SUM 
# 1 url of file to download
# 2 sha1sum of file
# 3 (optional) folder to extract to under $TEMP. Some source tarballs have their files under a folder, others' tarball them directly.
# We assume they are tarballed under a nice folder, but if they aren't, use $3 to supply the parent folder name (usually just the dep name).
download_extract() {
    cd $CACHE
    FILE=`basename "$1"`
        if [ -x "`which wget`" ] ; then
            try wget -nd -c --read-timeout=300 --retry-connrefused --header "Accept-Encoding: gzip,deflate" "$1"
        elif [ -x "`which curl`" ]; then
            try curl -L -o "$FILE" -C - --header "Accept-Encoding: gzip,deflate" "$1"
        else 
            echo "wget/curl not found, can't download dependencies."
        fi
    verify_sha1sum $2 "$FILE"
 
    if [ `echo "$FILE" | awk -F . '{print $NF}'` = bz2 ] ; then
        try tar -C "$TEMP"/"$3" -xjf $FILE
    elif [ `echo "$FILE" | awk -F . '{print $NF}'` = gz  ] ; then
        try tar -C "$TEMP"/"$3" -xzf $FILE
    else
        die "Don't know how to extract this file".
    fi
}

# Build and install the dependency
# $1 = dependency's folder name
# $2 = configure flags needed
build()
{
    cd $TEMP/$1
    try ./configure $2 
    try make 
    try make install 
    cd $OLDDIR
}

#-------------------------------------------------------------
# Setup build environment.
initbuild() {
mkdir -p "$BUILD_DIR/usr/include"
mkdir -p "$BUILD_DIR/usr/lib"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/etc"
mkdir -p "$BUILD_DIR/usr/man/man1"
}

# Defining the versions here makes upgrades a ton easier.
export FONTCONFIG_VERSION="2.6.0"
export FONTFORGE_VERSION="20080828"
export FREETYPE_VERSION="2.3.9"
export LCMS_VERSION="1.17"
export LIBGCRYPT_VERSION="1.4.4"
export LIBGPHOTO2_VERSION="2.4.2"
export LIBGNUTLS_VERSION="2.8.0"
export LIBGPG_ERROR_VERSION="1.7" 
export LIBJPEG_VERSION="7"
export LIBPNG_VERSION="1.2.37"
export LIBSANE_VERSION="1.0.18"
export LIBUSB_VERSION="0.1.12"
export LIBXML2_VERSION="2.7.3"
export LIBXSLT_VERSION="1.1.24"
export PKG_CONFIG_VERSION="0.23"
export ZLIB_VERSION="1.2.3"

# Individual dependencies:
install_fontconfig() {
    download_extract "http://fontconfig.org/release/fontconfig-"$FONTCONFIG_VERSION".tar.gz" 93752566b8327485b153bd156049614f779b4c57 .
    build "fontconfig-$FONTCONFIG_VERSION" "--silent --prefix=$BUILD_DIR/usr"
}

install_fontforge() {
    download_extract "http://kent.dl.sourceforge.net/sourceforge/fontforge/fontforge_full-"$FONTFORGE_VERSION".tar.bz2" 2aa448e20ed78399786a3e63ccbada1a2f546d59 .

    # On OS X, it attempts to install a Fontforge.app to /Applications, even if you've specified --prefix!
    # Hack around that (FIXME: is there a cleaner way?):
    cd "$TEMP/fontforge-$FONTFORGE_VERSION"
    sed -e '/FontForge.app/d' < Makefile.static.in > Makefile.static.in.tmp
    mv Makefile.static.in.tmp Makefile.static.in
    sed -e '/FontForge.app/d' < Makefile.dynamic.in > Makefile.dynamic.in.tmp
    mv Makefile.dynamic.in.tmp Makefile.dynamic.in
    build "fontforge-$FONTFORGE_VERSION" "--silent --enable-shared --prefix=$BUILD_DIR/usr --without-x --with-freetype-src=$TEMP/freetype-$FREETYPE_VERSION"
}

install_freetype() {
    download_extract "http://nongnu.askapache.com/freetype/freetype-"$FREETYPE_VERSION".tar.gz" 2c82a4f87b076c13d878129c8651645803585ff4 .
    build "freetype-$FREETYPE_VERSION" "--silent --prefix=$BUILD_DIR/usr"
}

install_jpeg() {
    download_extract "http://www.ijg.org/files/jpegsrc.v"$LIBJPEG_VERSION".tar.gz" 88cced0fc3dbdbc82115e1d08abce4e9d23a4b47 .
    ln -s `which glibtool` "$TEMP/jpeg-$LIBJPEG_VERSION/libtool"
    build "jpeg-$LIBJPEG_VERSION" "--silent --enable-shared --prefix=$BUILD_DIR/usr"
}

install_lcms() {
    download_extract "http://www.littlecms.com/lcms-"$LCMS_VERSION".tar.gz" 083eb02890048f843803a5974914e54b5e034493 .
    build "lcms-$LCMS_VERSION" "--silent --enable-shared --prefix=$BUILD_DIR/usr"
}

install_libgcrypt() {
    download_extract "ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-"$LIBGCRYPT_VERSION".tar.gz" 6f156593ce0833856b59580a7d430d0a5153b324 .
    build "libgcrypt-$LIBGCRYPT_VERSION" "--silent --enable-shared --prefix=$BUILD_DIR/usr"
}

install_libgnutls() {
    download_extract "ftp://ftp.gnu.org/pub/gnu/gnutls/gnutls-"$LIBGNUTLS_VERSION".tar.bz2" 7c102253bb4e817f393b9979a62c647010312eac .
    build "gnutls-$LIBGNUTLS_VERSION" "--silent --enable-shared --prefix=$BUILD_DIR/usr"
}

install_libgpg_error() {
    download_extract "ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-"$LIBGPG_ERROR_VERSION".tar.gz" 46675fb1d0b4dc18d43c3ce9dd9453ee0634be64 .
    build "libgpg-error-$LIBGPG_ERROR_VERSION" "--silent --enable-shared --prefix=$BUILD_DIR/usr"
}

install_libgphoto() {
    download_extract "http://dfn.dl.sourceforge.net/sourceforge/gphoto/libgphoto2-"$LIBGPHOTO2_VERSION".tar.gz" bf8d8d9699ad94d967ad347b2910af1e0aadc284 .
    build libgphoto2-$LIBGPHOTO2_VERSION "--with-drivers=adc65,agfa_cl20,aox,barbie,canon,clicksmart310,digigr8,digita,dimera3500,directory,enigma13,fuji,gsmart300,hp215,iclick,jamcam,jd11,kodak_dc120,kodak_dc210,kodak_dc240,kodak_dc3200,kodak_ez200,konica,konica_qm150,largan,lg_gsm,mars,dimagev,mustek,panasonic_coolshot,panasonic_l859,panasonic_dc1000,panasonic_dc1580,pccam300,pccam600,polaroid_pdc320,polaroid_pdc640,polaroid_pdc700,ptp2,ricoh,ricoh_g3,samsung,sierra,sipix_blink2,sipix_web2,smal,sonix,sony_dscf55,soundvision,spca50x,sq905,stv0674,stv0680,sx330z,toshiba_pdrm11 --enable-shared --prefix=$BUILD_DIR/usr"
}

install_libpng() {
    download_extract "ftp://ftp.simplesystems.org/pub/png/src/libpng-"$LIBPNG_VERSION".tar.bz2" 4e2a967a24db88e9a2f6a8bab3fa1fd94bc68c00 .
    build "libpng-$LIBPNG_VERSION" "--silent --enable-shared --prefix=$BUILD_DIR/usr"
}

install_libusb() {
    download_extract "http://heanet.dl.sourceforge.net/sourceforge/libusb/libusb-"$LIBUSB_VERSION".tar.gz" 599a5168590f66bc6f1f9a299579fd8500614807 .
    build "libusb-$LIBUSB_VERSION" "--silent --enable-shared --prefix=$BUILD_DIR/usr --disable-build-docs"
}

install_libxml() {
    download_extract "ftp://xmlsoft.org/libxml2/libxml2-"$LIBXML2_VERSION".tar.gz" fd4e427fb55c977876bc74c0e552ef7d3d794a07 .
    build "libxml2-$LIBXML2_VERSION" "--silent --enable-shared --prefix=$BUILD_DIR/usr"
}

install_libxslt() {
    download_extract "ftp://xmlsoft.org/libxml2/libxslt-"$LIBXSLT_VERSION".tar.gz" b5402e24abff5545ed76f6a55049cbebc664bd58 .
    build "libxslt-$LIBXSLT_VERSION" "--silent --enable-shared --prefix=$BUILD_DIR/usr --with-libxml-src=$TEMP/libxml2-$LIBXML2_VERSION"
}

install_pkgconfig() {
    download_extract "http://pkgconfig.freedesktop.org/releases/pkg-config-"$PKG_CONFIG_VERSION".tar.gz" b59dddd6b5320bd74c0f74b3339618a327096b2a .
    build "pkg-config-$PKG_CONFIG_VERSION" "--silent --enable-shared --prefix=$BUILD_DIR/usr"
}

install_sane_backends() {
    download_extract "ftp://ftp.sane-project.org/pub/sane/old-versions/sane-backends-"$LIBSANE_VERSION"/sane-backends-"$LIBSANE_VERSION".tar.gz" f4c360b87ced287e4015a0dafd766ad885c539e1 .
    build "sane-backends-$LIBSANE_VERSION" "--silent --enable-shared --prefix=$BUILD_DIR/usr --with-gphoto2"
}

install_zlib() {
    download_extract  "ftp://ftp.simplesystems.org/pub/png/src/zlib-"$ZLIB_VERSION".tar.gz" 60faeaaf250642db5c0ea36cd6dcc9f99c8f3902 .
    build "zlib-$ZLIB_VERSION" "--shared --prefix=$BUILD_DIR/usr"
}

#----------------------------------------------------------------------------
# Now actually do something...

#Setup our build environment:
initbuild

export CPPFLAGS="-I$BUILD_DIR/usr/include"
export CFLAGS="-I$BUILD_DIR/usr/include"
export LDFLAGS="-L$BUILD_DIR/usr/lib"
export PATH="$BUILD_DIR/usr/bin":$PATH
export PKG_CONFIG_PATH="$BUILD_DIR/usr/lib/pkgconfig"

# Now build/install. Order is important!
    install_pkgconfig
    install_lcms
    install_jpeg
    install_zlib
    install_libpng
    install_libgpg_error
    install_libgcrypt
    install_libgnutls
    install_freetype
    install_libxml
    install_libxslt
    install_fontconfig
    install_libusb
    install_libgphoto
    install_sane_backends
    install_fontforge

# Give the user a build script they can use:
    cat > build.sh <<_EOF_
#!/bin/sh

export BUILD_DIR=\$HOME/.winedeps

export CPPFLAGS="-I\$BUILD_DIR/usr/include"
export CFLAGS="-I\$BUILD_DIR/usr/include"
export LDFLAGS="-L\$BUILD_DIR/usr/lib"
export PATH=\$PATH:"\$BUILD_DIR/usr/bin"
export DYLD_LIBRARY_PATH="\$BUILD_DIR/usr/lib":\$LIBDIR:\$DYLD_LIBRARY_PATH
export DYLD_FALLBACK_LIBRARY_PATH="\$BUILD_DIR/usr/lib":\$LIBDIR:\$DYLD_FALLBACK_LIBRARY_PATH
export PKG_CONFIG_PATH="\$BUILD_DIR/usr/lib/pkgconfig"
export CONFIGUREFLAGS='--disable-win16 --without-hal --without-capi'

./configure \$CONFIGUREFLAGS
make depend
make

_EOF_

chmod +x build.sh
echo "Place build.sh in your wine source tree and run './build.sh' to compile Wine."

rm -rf $TEMP
