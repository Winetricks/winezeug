add_library(mylib mylib.c)
add_executable(mymain mymain.c)
target_link_libraries(mymain mylib)
