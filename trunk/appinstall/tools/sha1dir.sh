#!/bin/bash
# Script to automate Winezeug appinstall sha1'ing of a directory
# Copyright 2009 Thomas Heckel
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

version="v2009-08-03"
USAGE_TEXT="get the SHA1 commands needed by Winezeug appinstall scripts
for files of a directory.

SYNOPSIS:
`basename $0` [options] <wisheddir> [savefile]

--force -f
    overwrite savefile if it already exists.

--help -h -?
    display this help and exit.

--version -v
    output version information and exit.

If no \"savefile\" name is given output is put onto STDOUT.
The filename paths are stored relatively from \"wisheddir\" on."
    
#
# input checking:
#

while getopts ":fh?v-:" OPTION
do
	case $OPTION in
	f)	force="true";;
	h) echo "$USAGE_TEXT"
		exit 0;;
	'?') echo "$USAGE_TEXT"
		exit 0;;
	v) echo $version
		exit 0;;
	-)	case $OPTARG in

		#force overwrite
		force) force="true";;
		help) echo "$USAGE_TEXT"
			exit 0;;
		version) echo $version
			exit 0;;
			
		# DEFAULT
		*)	echo "option \`--$OPTARG' not recognized. Use `basename $0` --help for script usage."
		exit 1;;
		
		esac;;
	
	# DEFAULT
	*)	echo "option \`-$OPTARG' not recognized. Use `basename $0` --help for script usage."
		exit 1;;
	esac
done
# shift out all recognized options from argument list
shift $(($OPTIND -1))

if [ $# -ne 1 -a $# -ne 2 ]; then
    echo "$USAGE_TEXT"
    exit 2
fi

if [ ! -d "$1" ]; then
    echo "parameter <wisheddir> must be a directory. Script stopped."
    exit 3
fi

if [ $# -eq 2 -a -e "$2" ]; then
	if [ -z $force ]; then
		echo "savefile name \"$2\" already exists! Overwrite file? (y/N)"
		read answer
		case "$answer" in
		[yY])   rm -f "$2";;
		*)  echo "Script stopped."
			exit 4;;
		esac
	else
		rm -f "$2"
	fi
fi


#
# functions
#

AHKstring ()
{
    # escape AHK string special characters
    str="$( echo "$1" | sed -e 's/[,%\`; ]/\`&/g' )"

    str="$( echo "$str" | sed -e 's/::/\`::/g' )"
    str="$( echo "$str" | sed -e 's/[\n]/\`n/g' )"
    str="$( echo "$str" | sed -e 's/[\r]/\`r/g' )"
    # backspace needs special treatment
    str="$( echo "$str" | sed -e 's/'`echo $'\b'`'/`b/g' )"
    str="$( echo "$str" | sed -e 's/[\t]/\`t/g' )"
    str="$( echo "$str" | sed -e 's/[\v]/\`v/g' )"
    str="$( echo "$str" | sed -e 's/[\a]/\`a/g' )"
    str="$( echo "$str" | sed -e 's/[\f]/\`f/g' )"

    str="$( echo "$str" | sed -e 's/[\"]/\"\"/g' )"

    # convert UNIX path style to DOS path style
    str="$( echo "$str" | sed -e 's/[\/]/\\/g' )"
    echo "$str"
}


# Regex for prefixed filepath
RGXPATH="$( echo "$1" | sed -e 's/[/\^$.|?*#()]/\\&/g' )"

RemovePrefixPath ()
{
    # remove prefixed filepath
    filename="$( echo "$1" | sed -e s/^$RGXPATH// )"
    filename="$( echo "$filename" | sed -e 's/^\///' )"
    echo "$filename"
}


#
# now the processing:
#

# Caveat: Dollar signs in file names are only handled correctly by bash
# in next line and in for-loop
filelist="$( find "$1" -type f -print0 | xargs -0 ls -1 )"
echo "$filelist" > filelist
# Workaround: Line feed is intentional; \n and \012 didn't work under Ubuntu
OLDIFS=$IFS IFS=$'
'
for j in $filelist
do
    sharesult=$( sha1sum $j | sed -e 's/\(\w*\).*/\1/' )

    filename=`RemovePrefixPath "$j"`
    filename=`AHKstring "$filename"`

    result="$( echo "SHA1(\"$( echo "$sharesult" )\", \"$( echo "$filename" )\")" )"

    if [ $# -eq 2 ]; then
        echo "$result" >> "$2"
    else
        echo "$result"
    fi
done


# get code for testing existance of all directories.
dirlist="$( find "$1" -type d -print0 | xargs -0 ls -d )"
for j in $dirlist
do
    dirname=`RemovePrefixPath "$j"`

    # do not output empty (e.g. ".") directory
    if [ -n "$dirname" ]; then
        dirname=`AHKstring "$dirname"`
        result="$( echo "CHECK_DIR(\"$( echo "$dirname" )\")" )"

        if [ $# -eq 2 ]; then
            echo "$result" >> "$2"
        else
            echo "$result"
        fi
    fi
done

IFS=$OLDIFS
exit 0
