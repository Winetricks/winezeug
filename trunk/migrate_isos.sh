#!/bin/sh
# Rename all sha1sum-named isos (wisotool convention) with their volume name (wisotool2 convention)
# Assumes you've already done something like
#   mkdir -p ~/.cache/winetricks
#   mv ~/.winetrickscache/* ~/.cache/winetricks/*
#   mv ~/.wisotoolcache/* ~/.cache/winetricks/
#   mv ~/.wisotool/cache/* ~/.cache/winetricks/
#   rmdir ~/.winetrickscache ~/wisotoolcache ~/.wisotool/cache

set -e
cd ~/.cache/winetricks
for filename in */????????????????????????????????????????.iso
do
    volname=`sh ~/winezeug/wisotool2 volnameof=$filename`
    if ! test "$volname"
    then
        echo "Cannot get volume name of $filename"
        exit 1
    fi
    dirname=`dirname $filename`
    echo "$filename -> $dirname/$volname.iso"
    mv "$filename" "$dirname/$volname.iso"
done 
