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

lpw_assign_jobs_to_slaves_fairly()
{
    # Hand a job to any slave that doesn't have one.
    # Don't queue more than one job for any one slave,
    # since we don't want to risk a small job getting
    # stuck behind a huge one.
    for slave in $slaves
    do
        numjobs=`ls shared/$slave/[0-9]* 2>/dev/null | wc -l || true`
        if test "$numjobs" = "" || test "$numjobs" -lt 1
        then
            lpw_assign_job_to_slave $slave || break
	fi
    done
}

while true
do
    # It may be bad to hit the pop server every 15 seconds, so do it every 30.
    lpw_receive_jobs

    for i in 1 2
    do
        lpw_send_outbox
        lpw_assign_jobs_to_slaves_fairly
        sleep 15
    done
done
