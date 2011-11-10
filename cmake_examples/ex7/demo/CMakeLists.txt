add_subdirectory(../libsrc libsrc)
include_directories(../libsrc)
ADD_EXECUTABLE(mymain mymain.c)
target_link_libraries(mymain mylib)
