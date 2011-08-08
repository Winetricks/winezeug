#!/bin/sh
# Script to demonstrate setting up buildbot
# Taken straight from the tutorial, http://buildbot.net/buildbot/tutorial/
set -x
set -e

srcdir=`dirname $0`
srcdir=`cd $srcdir; pwd`

init_master() {
    sudo apt-get install python-dev virtualenv
    # Master
    cd $HOME
    virtualenv --no-site-packages master-sandbox
    cd $HOME/master-sandbox
    source bin/activate
    easy_install buildbot
    buildbot create-master master
    mv master/master.cfg.sample master/master.cfg
}

start_master() {
    cd $HOME/master-sandbox
    source bin/activate
    buildbot start master/master.cfg
}

init_slave {
    sudo apt-get install python-dev virtualenv
    sudo apt-get install lxc python-configobj python-netaddr
    cd $HOME
    virtualenv --no-site-packages slave-sandbox
    cd $HOME/slave-sandbox

    # Get and install arkose
    cd $HOME/slave-sandbox
    bzr branch lp:~arkose-devel/arkose/arkose-trunk
    cd arkose-trunk
    patch -p0 < ar2.diff
    sudo python Setup.py install
    cd ..

    # Set up slave buildbot
    source bin/activate
    easy_install buildbot
    buildbot create-slave slave
    mv slave/slave.cfg.sample slave/slave.cfg
}

start_slave() {
    cd $HOME/slave-sandbox
    source bin/activate
    buildbot start slave/slave.cfg
}

case "$1" in
c|clean) rm -rf $HOME/slave-sandbox $HOME/master-sandbox ;;
im|init_master) init_master;;
sm|start_master) start_master;
is|init_slave) init_slave;;
ss|start_slave) start_slave;;
*) echo "bad arg"; exit 1;;
esac
