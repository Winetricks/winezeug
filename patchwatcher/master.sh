#!/bin/sh
#
# Simple continuous master for gathering and assigning jobs to slaves
#
# Copyright 2008 Robert Shearman
# License: LGPL

. `dirname $0`/libpatchwatcher.sh

lpw_init `dirname $0`

set -e
set -x

slaves=`cd shared; echo slave*`

while true
do
    lpw_receive_jobs
    lpw_send_outbox
    for slave in $slaves
    do
        numjobs=`echo shared/$slave/[0-9]* 2>/dev/null | wc -l || true`
        if test "$numjobs" = "" || test "$numjobs" -lt 2
        then
            lpw_assign_job_to_slave $slave || break
	fi
    done
    sleep 30
done
