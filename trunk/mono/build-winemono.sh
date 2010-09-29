#!/bin/bash -e
CURDIR="`pwd`"
MINGW=i386-mingw32msvc
CROSS_DIR=/opt/cross/$MINGW
COPY_DLLS="libgio*.dll libglib*.dll libgmodule*.dll libgthread*.dll libgobject*.dll"
INSTALL_DESTDIR="$CURDIR"
PROFILES="net_1_1 net_2_0 net_3_5"
ORIGINAL_PATH="$PATH"
REBUILD=0

# If CC is set, it will conflict, unset it
unset CC

export CPPFLAGS_FOR_EGLIB CFLAGS_FOR_EGLIB CPPFLAGS_FOR_LIBGC CFLAGS_FOR_LIBGC

function setup ()
{
    local pcname

    CROSS_BIN_DIR="$CROSS_DIR/bin"
    CROSS_DLL_DIR="$CROSS_DIR/bin"
    CROSS_PKG_CONFIG_DIR=$CROSS_DIR/lib/pkgconfig
    PATH=$CROSS_BIN_DIR:$PATH

    export PATH

    NOCONFIGURE=yes
    export NOCONFIGURE

    MONO_VERSION=`git describe --tags 2>/dev/null`
    if test x"$MONO_VERSION" = x; then
        MONO_VERSION=mono-`grep AM_INIT_AUTOMAKE configure.in | cut -d ',' -f 2|tr -d '\)'`
    fi
    MONO_PREFIX=$INSTALL_DESTDIR/$MONO_VERSION
    echo Mono Win32 installation prefix: $MONO_PREFIX
}

function build ()
{
    if test 1 != $REBUILD || test ! -e configure; then
        ./autogen.sh 

        BUILD="`./config.guess`"

        if [ -f ./Makefile ]; then
	    rm -rf autom4te.cache
        fi
    fi

    if test 1 != $REBUILD; then
        rm -rf "$CURDIR/build-cross-wine"
        rm -rf "$CURDIR/build-cross-wine-mcs"
    fi

    if [ ! -d "$CURDIR/build-cross-wine" ]; then
        mkdir "$CURDIR/build-cross-wine"
    fi

    cd "$CURDIR/build-cross-wine"
    if test 1 != $REBUILD || test ! -e Makefile; then
        ../configure --prefix="$CURDIR/build-cross-wine-install" --with-crosspkgdir=$CROSS_PKG_CONFIG_DIR --build=$BUILD --target=$MINGW --host=$MINGW --enable-parallel-mark --program-transform-name="" --with-tls=none --disable-mcs-build --disable-embed-check --enable-win32-dllmain=yes --with-libgc-threads=win32 PKG_CONFIG="$(which pkg-config) --define-variable=prefix=${CROSS_DIR}" || exit 1
    fi
    make || exit 1
    rm -rf "$CURDIR/build-cross-wine-install"
    make install || exit 1
    cd "$CURDIR"

    if [ ! -d "$CURDIR/build-cross-wine-mcs" ]; then
	mkdir "$CURDIR/build-cross-wine-mcs"
    fi

    rm -rf autom4te.cache
    unset PATH
    PATH="$ORIGINAL_PATH"
    export PATH
    cd "$CURDIR/build-cross-wine-mcs"
    if test 1 != $REBUILD || test ! -e Makefile; then
        ../configure --prefix="$CURDIR/build-cross-wine-mcs-install" --enable-parallel-mark || exit 1
    fi
    make || exit 1
    rm -rf "$CURDIR/build-cross-wine-mcs-install"
    make install || exit 1
}

function doinstall ()
{
    if [ -d "$MONO_PREFIX" ]; then
	rm -rf "$MONO_PREFIX"
    fi

    mkdir -p "$MONO_PREFIX"

    cd "$CURDIR/build-cross-wine-install"
    cp -rfv bin lib "$MONO_PREFIX"

    cd "$CURDIR/build-cross-wine-mcs-install"
    cp -rfv lib/mono "$MONO_PREFIX"/lib
    cp -rfv share etc "$MONO_PREFIX"

    for dll in $COPY_DLLS; do
	cp -ap "$CROSS_DLL_DIR"/$dll "$MONO_PREFIX/bin"
    done

    rm -rf "$CURDIR/build-cross-wine-install" "$CURDIR/build-cross-wine-mcs-install"

    rm -f "$CURDIR/$MONO_VERSION".tar.gz
    cd $INSTALL_DESTDIR
    tar cvvzf "$CURDIR/$MONO_VERSION".tar.gz $MONO_VERSION

}

function usage ()
{
    cat <<EOF
Usage: build-wine.sh [OPTIONS]

where OPTIONS are:

 -d DIR     Sets the location of directory where MINGW is installed [$CROSS_DIR]
 -m MINGW   Sets the MINGW target name to be passed to configure [$MINGW]
 -r         Rebuild (skips configure)
EOF

    exit 1
}

pushd . > /dev/null

while getopts "d:m:rh" opt; do
    case "$opt" in
	d) CROSS_DIR="$OPTARG" ;;
	m) MINGW="$OPTARG" ;;
	r) REBUILD=1 ;;
	*) usage ;;
    esac
done

setup
build
doinstall

popd > /dev/null
