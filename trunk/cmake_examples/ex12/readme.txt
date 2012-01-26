How to build both "Hello, JNI" in both 32 and 64 bits with cmake.

If you don't set JAVA_HOME explicitly before running cmake,
you may need the patches from
http://public.kitware.com/Bug/view.php?id=12878 and
http://public.kitware.com/Bug/view.php?id=12880
to find the system java on Ubuntu. 
