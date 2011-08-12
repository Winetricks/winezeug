#!/bin/sh
# Executable version of http://buildbot.net/buildbot/tutorial/
# Copyright 2011, Dan Kegel
# Dual licensed, GPL and LGPL, suitable for inclusion in both buildbot and wine

set -x
set -e

TOP=$HOME/tmp/buildbot

install_prereqs() {
    # For Ubuntu.  Other systems may differ.
    sudo apt-get install python-dev python-virtualenv
}

destroy() {
    stop_master || true
    stop_slave || true
    rm -rf $TOP || true
}

init_master() {
    (
    # Master
    mkdir -p $TOP
    cd $TOP
    virtualenv --no-site-packages sandbox
    cd $TOP/sandbox
    . bin/activate
    if true
    then
        easy_install buildbot
    else
        # You can install from source into the sandbox if you need bugfixes 
        # not yet in the binary easy_install, e.g.:
        wget -c http://buildbot.googlecode.com/files/buildbot-0.8.4p2.tar.gz
        tar -xzvf buildbot-0.8.4p2.tar.gz
        cd buildbot-0.8.4p2
        python setup.py install
        cd ..
    fi
    buildbot create-master master
    mv master/master.cfg.sample master/master.cfg
    )
}

start_master() {
    (
    cd $TOP/sandbox
    . bin/activate
    buildbot start $VIRTUAL_ENV/master
    )
}

stop_master() {
    (
    cd $TOP/sandbox
    . bin/activate
    buildbot stop $VIRTUAL_ENV/master
    )
}

init_slave() {
    (
    mkdir -p $TOP
    cd $TOP
    test -d sandbox || virtualenv --no-site-packages sandbox
    cd $TOP/sandbox
    . bin/activate
    easy_install buildbot-slave
    buildslave create-slave slave localhost:9989 example-slave pass
    )
}

start_slave() {
    (
    cd $TOP/sandbox
    . bin/activate
    buildslave start $VIRTUAL_ENV/slave
    )
}

stop_slave() {
    (
    cd $TOP/sandbox
    . bin/activate
    buildslave stop $VIRTUAL_ENV/slave
    )
}

all() {
    destroy
    install_prereqs
    init_master
    start_master
    init_slave
    start_slave
}

case "$1" in
d|destroy) destroy;;
ip|install_prereqs) install_prereqs;;
im|init_master) init_master;;
sm|start_master) start_master;;
is|init_slave) init_slave;;
ss|start_slave) start_slave;;
tm|stop_master) stop_master;;
ts|stop_slave) stop_slave;;
lm|log_master) tail -f $TOP/sandbox/master/twistd.log;;
ls|log_slave) tail -f $TOP/sandbox/slave/twistd.log;;
all) all;;
*) echo "bad arg; expected destroy, install_prereqs, {init,start,log}_{master,slave}, or all"; exit 1;;
esac
