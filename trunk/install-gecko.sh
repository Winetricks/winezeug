#!/bin/sh
# Install the Gecko needed by modern wines
set -ex

install_gecko()
{
    case $1 in
    wine-1.1.2[789]*|wine-1.1.[34]*|wine-1.2*|wine-1.3|wine-1.3.[01]|wine-1.3.[0]-*)
        GECKO_VERSION=1.0.0
        GECKO_SHA1SUM=afa22c52bca4ca77dcb9edb3c9936eb23793de01
        ;;
    *)
        GECKO_VERSION=1.1.0
        GECKO_SHA1SUM=1b6c637207b6f032ae8a52841db9659433482714
        ;;
    esac

    if test ! -f /usr/share/wine/gecko/wine_gecko-$GECKO_VERSION-x86.cab
    then
        rm -f wine_gecko-$GECKO_VERSION-x86.cab
        wget http://downloads.sourceforge.net/wine/wine_gecko-$GECKO_VERSION-x86.cab

        gotsum=`sha1sum < wine_gecko-$GECKO_VERSION-x86.cab | sed 's/(stdin)= //;s/ .*//'`
        if [ "$gotsum"x != "$GECKO_SHA1SUM"x ]
        then
           echo "sha1sum mismatch!  Please try again."
           exit 1
        fi

        sudo mkdir -p /usr/share/wine/gecko
        sudo cp wine_gecko-$GECKO_VERSION-x86.cab /usr/share/wine/gecko/
    fi
}

# Install gecko for stable wine and the current dev branch
install_gecko wine-1.2
install_gecko wine-1.3.3
