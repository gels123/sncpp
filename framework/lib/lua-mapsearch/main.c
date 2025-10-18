#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "wrapper.h"
 
int main(void)
{
	void *handler = getInstance();
    int num = testFun(handler, 333, 2222);
    printf("====sdfadsf=====%d\n", num);

    return 0;
}