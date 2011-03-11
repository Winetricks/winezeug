#!/bin/sh
# Rename all sha1sum-named isos (wisotool convention) with their volume name (wisotool2 convention)
# Assumes you've already done something like
#   mkdir -p ~/.cache/winetricks
#   mv ~/.winetrickscache/* ~/.cache/winetricks/*
#   mv ~/.wisotoolcache/* ~/.cache/winetricks/
#   mv ~/.wisotool/cache/* ~/.cache/winetricks/
#   rmdir ~/.winetrickscache ~/wisotoolcache ~/.wisotool/cache

set -e
set -x
#cd ~/.cache/winetricks
for dir in *
do
    if cd $dir
    then
        for filename in ????????????????????????????????????????.iso
        do
	    if test -f "$filename"
	    then
                volname=`winetricks volnameof=$filename`
                if ! test "$volname"
                then
                    echo "Cannot get volume name of $filename"
                    exit 1
                fi
                echo "$filename -> $volname.iso"
                ln -s "$filename" "$volname.iso"
	    fi
	done
	cd ..
    fi
done 
