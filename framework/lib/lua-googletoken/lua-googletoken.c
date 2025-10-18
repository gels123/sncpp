#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "lua.h"
#include "lauxlib.h"

// #include "../shared_header.h"

/*
fork from https://github.com/ymvunjq/translate
*/

int RL(int a,char b[],int lenB)
{
    int i = 0;
    for (; i < lenB-2; i=i+3)
    {
        int d =  b[i+2];
        //printf("before d = %d\n",d );
        if (d>=97)
        {
            d = ((int) d - 87);
            //printf("------%d\n",d );
        }
        else
        {
            char tmpD = d;
            char tmpDArray[16]={0};
            sprintf(tmpDArray,"%c",tmpD);
            d = atoi(tmpDArray);
            //printf("======%d\n",d );
        }
        //printf("--------d = %d\n", d);
        if (43 == (int)(b[i+1]) )
        {
            unsigned int tmpA = a;
            // a = tmpA >> d;
            d =(int)(tmpA >> d) ;//a >> d;
            //printf(">>>>>>>>>>>a=%d d = %d\n", a,d);
        }
        else
        {
            d =  (int) (a << d);
            //printf("<<<<<<<<a=%d d = %d\n", a,d);
        }
        if (43 == (int)(b[i]) )
        {
            a = (int) (a + d);
        }
        else
        {
            a = a ^ d;
        }
        //printf("c=%d a=%d d=%d\n",i,a,d );
    }
    return a;
}

char * google_tk_challenge(char * s,int lenS,int win,char * mBuffer)
{
    //printf("lens =%d\n",lenS );
    static int lenUb = 9;
    static int lenVb = 6;
    char Vb[] = "+-a^+6";
    char Ub[] = "+-3^+b+-f";
    lenVb = strlen(Vb);
    lenUb = strlen(Ub);
    //printf("len  == %d,%d\n",lenVb,lenUb );
    int a = win;
    int i = 0;
    for (; i < lenS; ++i)
    {
        //printf("s=%d, %d\n",i,s[i] );
        if (0 > s[i])
        {
            a = a + s[i] + 256;
        }
        else
        {
            a = a + s[i];
        }
        //printf("for a=%d\n",a );
        a = RL(a,Vb,lenVb);
        //printf("RL=%d\n",a );
    }
    a = RL(a,Ub,lenUb);
    //printf("UB=%d\n",a );
    long tmpLong = a;
    if (tmpLong < 0)
    {
        //printf("a&=%d\n",(a & 2147483647) );
        tmpLong =  (tmpLong & 2147483647) + 2147483648;
    }

    //printf("mode=%d\n",tmpLong );
    tmpLong =  tmpLong % 1000000;
    //printf("finish=%d\n",tmpLong );
    // char * mBuffer = (char *) my_malloc(64);
    sprintf(mBuffer,"%u.%u",(unsigned int)tmpLong,(unsigned int) (tmpLong ^ win) );
    //printf("mydata=%s\n",mBuffer );
    return mBuffer;
}

int lua_f_googletoken_generate ( lua_State *L )
{
    if ( !lua_isstring ( L, 1 ) ) {
        lua_pushnil ( L );
        return 1;
    }
    char myBuffer[32] = {0};

    size_t vlen = 0;
    const char *value = lua_tolstring ( L, 1, &vlen );
    //printf("strlen =%d ,tolstring len = %d ,utf len=%d\n",strlen(value),vlen,getUTF8Count(value) );
    //printf("==========\n");
    google_tk_challenge(value,strlen(value),402904,myBuffer);
    // char * dst = google_tk_challenge(value,strlen(value),402904,myBuffer);;

    // if ( dst == 0 ) {
    //     lua_pushnil ( L );
    //     return 1;
    // }

    int dlen = strlen(myBuffer) ;
    //printf("dlen ====%d\n", dlen);
    if ( myBuffer ) {
        lua_pushlstring ( L, myBuffer, dlen );

        // if ( dst != 0 ) {
        //     my_free ( dst );
        // }

        return 1;

    }
    //never exec
    lua_pushnil ( L );
    return 1;
}

LUALIB_API int luaopen_googletoken ( lua_State *L )
{
    luaL_checkversion(L);
    luaL_Reg l[] = {
        { "generate", lua_f_googletoken_generate },
        { NULL, NULL },
    };
    luaL_newlib(L,l);
    return 1;
}
