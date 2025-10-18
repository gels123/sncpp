#include <stdio.h>
#include <cstdlib>
#include <string.h>

struct str {
    char str[10];
    char cc;
};
int main()
{      
    struct str s;
    memset(s.str, '\0', sizeof(s.str));
    s.cc = 'a';
    strncpy(s.str, "11", sizeof(s.str)-1);
    printf("====%d   %s  ==%c\n", sizeof(s.str), s.str, s.cc);

    return 0;
} 