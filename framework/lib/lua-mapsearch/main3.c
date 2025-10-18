//gcc -o main2 main3.c
//测试内存泄漏: valgrind --tool=memcheck --leak-check=full --show-reachable=yes --trace-children=yes --log-file=./valgrind.log ./main2 &
#include <stdio.h>
#include <stdlib.h>
 
int main()
{
   int i, n;
   long long *a; //9223372036854775807
   long long b = 9223372036854775807+1;
   printf("b=%lld\n", b);
 
   printf("要输入的元素个数：");
   scanf("%d",&n);
 
   a = (long long*)calloc(n, sizeof(long long));
   printf("输入 %d 个数字：\n",n);
   for( i=0 ; i < n ; i++ ) 
   {
      scanf("%d",&a[i]);
   }
 
   printf("输入的数字为：");
   for( i=0 ; i < n ; i++ ) {
      printf("%d ",a[i]);
   }
   free (a);  // 释放内存
   return(0);
}