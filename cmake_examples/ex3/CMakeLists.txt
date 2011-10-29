add_subdirectory(libsrc)
add_executable(mymain mymain.c)
target_link_libraries(mymain mylib)
