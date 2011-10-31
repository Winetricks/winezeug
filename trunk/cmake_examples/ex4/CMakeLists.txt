cmake_minimum_required(VERSION 2.8)
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
