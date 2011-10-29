cmake_minimum_required(VERSION 2.8)
find_package(Boost 1.45 COMPONENTS date_time REQUIRED)
include_directories(${Boost_INCLUDE_DIRS})
add_definitions(${Boost_LIB_DIAGNOSTIC_DEFINITIONS})

add_executable(mymain mymain.cpp)
target_link_libraries(mymain ${Boost_LIBRARIES})
