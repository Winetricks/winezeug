add_library(mylib mylib.cc)
add_executable(mymain mymain.c)
target_link_libraries(mymain mylib)
