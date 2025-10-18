// gcc testmain.c -ldl -o testmain
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
//动态链接库路径
#define LIB_CACULATE_PATH "./rudpsvr.so"
//函数指针
typedef int (*CAC_FUNC)(int, int);
int main()
{
    void *handle;
    char *error;
    CAC_FUNC cac_func = NULL;
    //打开动态链接库
    handle = dlopen(LIB_CACULATE_PATH, RTLD_LAZY);
    if (!handle) {
        fprintf(stderr, "%s\n", dlerror());
        exit(EXIT_FAILURE);
    }
    fprintf(stdout, "handle=%p\n", handle);
    //清除之前存在的错误
    dlerror();
    //获取一个函数
    *(void **) (&cac_func) = dlsym(handle, "testf");
    if ((error = dlerror()) != NULL)  {
        fprintf(stderr, "%s\n", error);
        exit(EXIT_FAILURE);
    }
    printf("add: %d\n", (*cac_func)(2, 7));
    //关闭动态链接库
    dlclose(handle);
    return 0;
}