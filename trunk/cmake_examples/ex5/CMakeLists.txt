cmake_minimum_required(VERSION 2.6)
project(ex5 CXX C)

# Note: Google considers using the system copy of gtest harmful, see
# https://groups.google.com/forum/#!topic/googletestframework/zHy-rrKz_Ho/discussion
# Instead, they recommend that *every* package that uses gtest
# include gtest directly.  So, no using find_package(GTest)!
# And you should probably uninstall the system copy of gtest to
# avoid accidentally including it.
#
# gtest kind of prefers statically linking to the C runtime library,
# but that causes multiple definitions, so just tell them to use 
# cmake's defaults.  Setting this variable is a bit convoluted; since we 
# have to specify a doc string, use same one as gtest/CMakeLists.txt does.
SET(gtest_force_shared_crt on CACHE BOOL
  "Use shared (DLL) run-time lib even when Google Test is built as static lib.")

add_subdirectory(gtest)
include_directories(gtest/include)

add_executable(mymain mymain.cpp)
target_link_libraries(mymain gtest_main)
