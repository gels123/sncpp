#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>

int f(int a, int b) {
    return a+b;
}

int main()
{
    typedef int (*fun)(int a, int b);
    fun ff = &f;
    std::cout<<ff(100, 200) << std::endl;

    return 0;
} 