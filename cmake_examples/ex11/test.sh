#!/bin/sh
set -e
set -x
# Test whether the demo works with various alternative JDKs installed

uninstall_all_java() {
    yes | sudo apt-get -y remove \
        java-common \
        icedtea-7-jre-jamvm \
        openjdk-7-jdk openjdk-7-jre openjdk-7-jre-headless openjdk-7-jre-lib \
        icedtea-6-jre-jamvm \
        openjdk-6-jdk openjdk-6-jre openjdk-6-jre-headless openjdk-6-jre-lib \
        gcj-4.6-jdk gcj-4.6-jre gcj-4.6-jre-headless \
        gcj-4.5-jdk gcj-4.5-jre gcj-4.5-jre-headless \
        gcj-4.4-jdk gcj-4.4-jre gcj-4.4-jre-headless
    yes | sudo apt-get -y autoremove
}

install_one_java() {
    sudo aptitude -y install $*

    if grep precise /etc/issue
    then
        # Work around bug in ubuntu 12.04, see
        # https://bugs.launchpad.net/ubuntu/+source/openjdk-6/+bug/905808
        case $* in
        openjdk-7-jdk)
           sudo /usr/share/debconf/frontend /var/lib/dpkg/info/openjdk-7-jre-headless\:amd64.postinst configure
           sudo /usr/share/debconf/frontend /var/lib/dpkg/info/openjdk-7-jdk\:amd64.postinst configure
           ;;
        openjdk-6-jdk)
           sudo /usr/share/debconf/frontend /var/lib/dpkg/info/openjdk-6-jre-headless\:amd64.postinst configure
           sudo /usr/share/debconf/frontend /var/lib/dpkg/info/openjdk-6-jdk\:amd64.postinst configure
           ;;
        esac
    fi
}

try() {
    uninstall_all_java
    install_one_java $*
    sh demo.sh
}

try openjdk-7-jdk
try openjdk-6-jdk
try gcj-4.6-jdk
try gcj-4.5-jdk
# gcj-4.4-jdk is broken, see
# https://bugs.launchpad.net/ubuntu/+source/gcj-4.4/+bug/917961
#try gcj-4.4-jdk 
