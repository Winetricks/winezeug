project(Hello Java CXX)

cmake_minimum_required(VERSION 2.8.6)

include(UseJava)

find_package(Java REQUIRED)

add_jar(Hello src/Hello.java)

find_package(JNI REQUIRED)

include_directories(${CMAKE_CURRENT_BINARY_DIR} ${JNI_INCLUDE_DIRS})

add_custom_command(
    OUTPUT
        CHello.h
    DEPENDS
        ${CMAKE_CURRENT_BINARY_DIR}/Hello.jar
    COMMAND
        ${Java_JAVAH_EXECUTABLE} -classpath ${CMAKE_CURRENT_BINARY_DIR}/Hello.jar -jni -d ${CMAKE_CURRENT_BINARY_DIR} Hello
)
add_library(CHello SHARED CHello.h src/CHello.cpp)
target_link_libraries(CHello CHello)
