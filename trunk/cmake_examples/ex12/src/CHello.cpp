#include "Hello.h"
#include <jni.h>
#include <stdio.h>
 
/* Note the extra 1.  JNI uses _ as a special symbol, so you have to escape
 * it by appending 1 if it appears in your method names.
 */
JNIEXPORT void JNICALL Java_Hello_print_1hello(JNIEnv *env, jobject obj)
{
    printf("Hello, world!\n");
}
