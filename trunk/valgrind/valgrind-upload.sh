#!/bin/sh
set -x
cd logs
DATE=`ls -d ????-??-??-??.?? | tail -1`
chmod 644 $DATE*.*
scp $DATE*.* kegel.com:public_html/kegel/wine/valgrind/logs
cd $DATE
chmod 644 *.txt
ssh kegel.com mkdir public_html/kegel/wine/valgrind/logs/$DATE
scp vg*.txt kegel.com:public_html/kegel/wine/valgrind/logs/$DATE
