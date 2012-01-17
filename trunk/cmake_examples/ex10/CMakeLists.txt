project(Hello Java)

cmake_minimum_required(VERSION 2.8.6)

include(UseJava)

FIND_PACKAGE(Java REQUIRED)

add_jar(Hello src/Hello.java)
