project(Hello Java CXX)

cmake_minimum_required(VERSION 2.8.6)

if($ENV{FORCE_32_BIT})
    # only build 32-bit binaries
    add_definitions("-m32") 
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -m32")
    set(CMAKE_SHARED_LIBRARY_C_FLAGS "${CMAKE_SHARED_LIBRARY_C_FLAGS} -m32")
    set(CMAKE_SHARED_LIBRARY_CXX_FLAGS "${CMAKE_SHARED_LIBRARY_CXX_FLAGS} -m32")
endif()

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
