#!/bin/sh
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

