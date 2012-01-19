cmake_minimum_required(VERSION 2.8)

if($ENV{FORCE_32_BIT})
    # only build 32-bit binaries
    add_definitions("-m32") 
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -m32")
    set(CMAKE_SHARED_LIBRARY_C_FLAGS "${CMAKE_SHARED_LIBRARY_C_FLAGS} -m32")
    set(CMAKE_SHARED_LIBRARY_CXX_FLAGS "${CMAKE_SHARED_LIBRARY_CXX_FLAGS} -m32")
endif()

# Turn off boost's autolinking feature, since it seems to guess wrong about the name of the library
add_definitions(-DBOOST_ALL_NO_LIB)
# Other options that might be useful
# set(Boost_USE_STATIC_LIBS        ON)
# set(Boost_USE_MULTITHREADED      ON)
# set(Boost_USE_STATIC_RUNTIME     OFF)
find_package(Boost 1.45 COMPONENTS date_time REQUIRED)
include_directories(${Boost_INCLUDE_DIRS})
add_definitions(${Boost_LIB_DIAGNOSTIC_DEFINITIONS})

add_executable(mymain mymain.cpp)
target_link_libraries(mymain ${Boost_LIBRARIES})
