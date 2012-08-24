#!/bin/sh
# Executable version of http://buildbot.net/buildbot/tutorial/
# Copyright 2011, Dan Kegel
# Dual licensed, GPL and LGPL, suitable for inclusion in both buildbot and wine

set -x
set -e

TOP=$HOME/tmp/buildbot

# Get email address of user from environment for use by the 'try' command.
# If not set, default to username@hostname.
EMAIL=${EMAIL:-$LOGNAME@`hostname`}

install_prereqs() {
    # For Ubuntu.  Other systems may differ.
    sudo apt-get install python-dev python-virtualenv
}

destroy() {
    if test -d $TOP
    then
        stop_master || true
        stop_slave || true
        rm -rf $TOP || true
    fi
}

init_master() {
    (
    # Master
    mkdir -p $TOP
    cd $TOP
    virtualenv --no-site-packages sandbox
    cd $TOP/sandbox
    . bin/activate
    if false
    then
        easy_install buildbot
    elif false
    then
        # Here's how to install from a source tarball
        wget -c http://buildbot.googlecode.com/files/buildbot-0.8.4p2.tar.gz
        tar -xzvf buildbot-0.8.4p2.tar.gz
        cd buildbot-0.8.4p2
        python setup.py install
        cd ..
    else
        # Here's how to install master from trunk
        # (Needed until buildbot-0.8.5 is released,
        # since it has fixes for the try server / mail notifier.)
        # BTW rerunning 'pip install -emaster' takes less than a second, 
        # and seems to be how buildbot developers test their code
        test -d buildbot-git || git clone https://github.com/buildbot/buildbot.git buildbot-git
        cd buildbot-git
        pip install -emaster
        cd ..
    fi
    buildbot create-master master
    cp master/master.cfg.sample master/master.cfg

    # Extend the tutorial a bit by adding a try scheduler and email notification
cat >> master/master.cfg <<_EOF_
###### One more scheduler ########
# Enable 'buildbot try' and set allowed usernames/passwords and port number
# You could also use Try_Jobdir, which uses ssh authentication; see
# http://buildbot.net/buildbot/docs/latest/Try-Schedulers.html
from buildbot.scheduler import Try_Userpass
c['schedulers'].append(Try_Userpass(
                            name='try',
                            builderNames=['runtests'],
                            port=5555, userpass=[('sampletryuser','sampletrypassword')]))

###### One more status target ########
from buildbot.status.mail import MailNotifier
mn = MailNotifier(
    fromaddr='$EMAIL',
    # By default, results are emailed to the email address given in the --who argument to try,
    # but you can add extra recipients like this:
    #extraRecipients=["user@example.com"],
    lookup="example-unused-if-try-users-are-email-addresses.com")
c['status'].append(mn)

_EOF_
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

do_try() {
    if test "$1" = ""
    then
        echo "need patch name"
        exit 1
    fi
    who=$2
    (
    cd $TOP/sandbox
    . bin/activate
    # Username, password, and port number must match those passed to
    # Try_Userpass in master.cfg
    # Note: if your project uses git, you probably want to add "-p 1"
    buildbot try --who $who --properties=comment="Description of patch for builder status page" --connect=pb --master=127.0.0.1:5555 --username=sampletryuser --passwd=sampletrypassword --diff=$1
    )
}

while test "$1"
do
    arg="$1"
    shift
    case "$arg" in
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
    try) do_try $1 $EMAIL; shift;;
    all) all;;
    *) echo "bad arg; expected destroy, install_prereqs, {init,start,log}_{master,slave}, try FOO.patch, or all"; exit 1;;
    esac
done
