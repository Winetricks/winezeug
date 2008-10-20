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

while true
do
    lpw_receive_jobs
    lpw_send_outbox
    while lpw_assign_job_to_slave slave
    do
        # Nothing to do
        true
    done
    sleep 30
done
