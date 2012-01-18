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

    # Work around bug in ubuntu 11.10 and 12.04, see
    # https://bugs.launchpad.net/ubuntu/+source/openjdk-6/+bug/905808
    if grep precise /etc/issue
    then
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
    if grep 11.10 /etc/issue
    then
        case $* in
        openjdk-6-jdk)
           sudo /usr/share/debconf/frontend /var/lib/dpkg/info/openjdk-6-jre-headless.postinst configure
           sudo /usr/share/debconf/frontend /var/lib/dpkg/info/openjdk-6-jdk.postinst configure
           ;;
        esac
    fi
}

try() {
    uninstall_all_java
    install_one_java $*
    sh demo.sh
}

if grep precise /etc/issue
then
    # Too broken on 11.10 to try, see
    # https://bugs.launchpad.net/ubuntu/+source/java-access-bridge/+bug/881218
    try openjdk-7-jdk
fi

try openjdk-6-jdk
try gcj-4.6-jdk
try gcj-4.5-jdk

if ! grep precise /etc/issue
then
    # gcj-4.4-jdk is broken on 12.04 alpha 1, see
    # https://bugs.launchpad.net/ubuntu/+source/gcj-4.4/+bug/917961
    try gcj-4.4-jdk 
fi
