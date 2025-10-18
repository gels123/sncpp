#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "lua.h"
#include "lauxlib.h"
#include "Judy.h"


#define JUDY_METATABLE  "Judy"
#define JUDY_INDEX_MAX 64
#define JUDYMALLOC JudyMalloc
#define JUDYFREE JudyFree

enum _JudyType{
    JUDYL = 1,
    JUDYSL = 2,
    JUDYHS = 3
};

enum _JudyDType{
    NUMBER  = LUA_TNUMBER,
    STRING  = LUA_TSTRING,
    ARRAY   = LUA_TLIGHTUSERDATA
};

static int
_JSLFA(lua_State *L) {
    Word_t    Bytes;                    // size of JudySL array.
    Pvoid_t  PJArray = lua_touserdata(L, 1);

    if (PJArray == NULL)
    {
        printf("_JSLFA PJArray is nil === \n");
        lua_pushboolean(L,0);
        return 1;
    }
    printf("JSLFA release judy array addr= %p\n",PJArray );

    JSLFA(Bytes, PJArray);              // free array

    PJArray = (Pvoid_t) NULL;
    printf("JSLFA release Judy array used %lu bytes of memory\n", Bytes);

    lua_pushboolean(L,1);
    return 1;
}

static int
_JLFA(lua_State *L) {
    Word_t    Bytes;                    // size of JudySL array.
    Pvoid_t  PJArray = lua_touserdata(L, 1);

    if (PJArray == NULL)
    {
        printf("_JLFA PJArray is nil === \n");
        lua_pushboolean(L,0);
        return 1;
    }
    printf("JLFA release judy array addr= %p\n",PJArray );

    JLFA(Bytes, PJArray);              // free array

    PJArray = (Pvoid_t) NULL;
    printf("JLFA release Judy array used %lu bytes of memory\n", Bytes);

    lua_pushboolean(L,1);
    return 1;
}

static int
_JLMU(lua_State *L) {
    Word_t    Bytes;                    // size of JudySL array.
    Pvoid_t  PJArray = lua_touserdata(L, 1);

    if (PJArray == NULL)
    {
        printf("is nil === \n");
        lua_pushnil(L);
        return 1;
    }
    printf("JLMU judy array addr= %p\n",PJArray );

    JLMU(Bytes, PJArray);

    printf("JLMU Judy array used %lu bytes of memory\n", Bytes);

    lua_pushinteger(L,Bytes);
    return 1;
}

static int
_JHSFA(lua_State *L) {
    Word_t    Bytes;                    // size of JudySL array.
    Pvoid_t  PJArray = lua_touserdata(L, 1);

    if (PJArray == NULL)
    {
        printf("_JHSFA PJArray is nil === \n");
        lua_pushboolean(L,0);
        return 1;
    }
    printf("HSFA release judy array addr= %p\n",PJArray );

    JHSFA(Bytes, PJArray);              // free array

    PJArray = (Pvoid_t) NULL;
    printf("HSFA release Judy array used %lu bytes of memory\n", Bytes);

    lua_pushboolean(L,1);
    return 1;
}

static int
_JSLG(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */

    if ( !lua_isuserdata ( L, 1 ) ) {
        lua_pushnil ( L );
        return 1;
    }

    Pvoid_t  PJArray = lua_touserdata(L, 1);

    if ( !lua_isstring ( L, 2 ) ) {
        printf("JSLG error,key is not a string \n");
        lua_pushnil ( L );
        return 1;
    }
    size_t keylen = 0;
    const char *keystring = lua_tolstring ( L, 2, &keylen );
    // printf("_JSLG key value = %s \n",keystring );
    // printf("jslg judyarray=%p\n", PJArray);

    PWord_t   PValue;                   // Judy array element.
    JSLG(PValue, PJArray, keystring);   // store string into array
    
    if (NULL != PValue)
    {
       // printf("jslg pvalue =%p value=%p argc =%d\n",PValue,*PValue,argc );
       if (argc == 2)
       {
           lua_pushlightuserdata(L,PValue);
           // printf("_JSLG arg=2 PValue ==%p\n",PValue);
           return 1;
       }
       else
       {
            short dType = lua_tonumber(L,3);
            if (NUMBER == dType)
            {
                lua_pushnumber(L,*PValue);
                return 1;
            }
            else if (STRING == dType)
            {
                lua_pushstring(L,(const char *) *PValue);
                return 1;
            }
            else if (ARRAY == dType)
            {
                printf("_JSLG PValue ==%p\n",PValue);
                lua_pushlightuserdata(L,*PValue);
                return 1;
            }
            else
            {
                // printf("_JSLG with nil type===============%p\n",PValue );
                lua_pushlightuserdata(L,PValue);
                return 1;
            }
       }
    }
    lua_pushnil ( L );
    return 1;
}

static int
_JLG(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */

    if ( !lua_isuserdata ( L, 1 ) ) {
        lua_pushnil ( L );
        return 1;
    }

    Pvoid_t  PJArray = lua_touserdata(L, 1);

    if ( !lua_isinteger ( L, 2 ) ) {
        printf("JLG error,key is not a integer \n");
        lua_pushnil ( L );
        return 1;
    }
    Word_t Index = lua_tointeger(L,2);
    // printf("JLG judyarray=%p\n", PJArray);

    PWord_t   PValue;                   // Judy array element.
    JLG(PValue, PJArray, Index);   // store string into array
    
    if (NULL != PValue)
    {
       // printf("JLG pvalue =%p value=%p\n",PValue,*PValue );
       if (argc == 2)
       {
           lua_pushlightuserdata(L,PValue);
           return 1;
       }
       else
       {
            short dType = lua_tonumber(L,3);
            if (NUMBER == dType)
            {
                lua_pushnumber(L,*PValue);
                return 1;
            }
            else if (STRING == dType)
            {
                lua_pushstring(L,(const char *) *PValue);
                return 1;
            }
            else if (ARRAY == dType)
            {
                lua_pushlightuserdata(L,*PValue);
                return 1;
            }
            else
            {
                lua_pushlightuserdata(L,PValue);
                return 1;
            }
       }
    }
    lua_pushnil ( L );
    return 1;
}

static int
_JHSG(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */

    if ( !lua_isuserdata ( L, 1 ) ) {
        lua_pushnil ( L );
        return 1;
    }

    Pvoid_t  PJArray = lua_touserdata(L, 1);

    if ( !lua_isstring ( L, 2 ) ) {
        printf("JHSG error,key is not a string \n");
        lua_pushnil ( L );
        return 1;
    }
    size_t keylen = 0;
    const char *keystring = lua_tolstring ( L, 2, &keylen );
    // printf("JHSG key value = %s \n",keystring );
    // printf("JHSG judyarray=%p\n", PJArray);

    PWord_t   PValue;                   // Judy array element.
    JHSG(PValue, PJArray, keystring,keylen);   // store string into array
    
    if (NULL != PValue)
    {
       // printf("JHSG pvalue =%p value=%p\n",PValue,*PValue );
       if (argc == 2)
       {
           lua_pushlightuserdata(L,PValue);
           return 1;
       }
       else
       {
            short dType = lua_tonumber(L,3);
            if (NUMBER == dType)
            {
                lua_pushnumber(L,*PValue);
                return 1;
            }
            else if (STRING == dType)
            {
                lua_pushstring(L,(const char *) *PValue);
                return 1;
            }
            else if (ARRAY == dType)
            {
                lua_pushlightuserdata(L,*PValue);
                return 1;
            }
            else
            {
                lua_pushlightuserdata(L,PValue);
                return 1;
            }
       }
    }
    lua_pushnil ( L );
    return 1;
}

static int
_new(lua_State *L) {
    lua_pushnil(L);
    return 1;
}

static int
_freestring(lua_State *L) {
    PWord_t   PValue = lua_touserdata(L, 1);
    // printf("free  === %p\n", PValue);
    short ret = 0;
    if (NULL != PValue)
    {   
        char * buf =(char*)(*PValue);
        // printf("free 2  === %p\n", buf);
        if (NULL != buf)
        {
            int len =  strlen(buf);
            // printf("free %s len=%d\n",buf,len );
            JUDYFREE(buf,len);
            ret = 1;
        }
    }
    lua_pushboolean(L,ret);
    return 1;
}

static int
_JSLI(lua_State *L) {
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        // printf("JSLI function,PJArrayis nil === \n");
        PJArray = (Pvoid_t) NULL;
    }

    // printf("jsli PJArray=%p\n", PJArray);
    if ( !lua_isstring ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    size_t keylen = 0;
    const char *keystring = lua_tolstring ( L, 2, &keylen );
    // printf("key value = %s \n",keystring );
    
    short valuetype = lua_type(L, 3);
    // printf("value  type = %d \n", valuetype);

    PWord_t   PValue;// Judy array element.
    if (LUA_TSTRING == valuetype)
    {
        size_t valuelen = 0;
        const char *valuestring = lua_tolstring ( L, 3, &valuelen );
        // printf("value string = %s\n", valuestring);
        JSLI(PValue, PJArray, keystring);
        if (NULL != PValue)
        {
            char * desValue = JUDYMALLOC(valuelen+1);
            memset(desValue,0,valuelen+1);
            memcpy(desValue,valuestring,valuelen);

            *PValue = desValue;
            lua_pushlightuserdata(L,PJArray);
            lua_pushlightuserdata(L,PValue);
            return 2;
        }
    }
    else if (LUA_TNUMBER == valuetype)
    {
        double value = lua_tonumber(L, 3);
        JSLI(PValue, PJArray, keystring);
        if (NULL != PValue)
        {
            *PValue = value;
            // printf("lua_number pvalue=%d ==\n",*PValue);
            lua_pushlightuserdata(L,PJArray);
            lua_pushlightuserdata(L,PValue);
            return 2;
        }
    }
    else if (LUA_TLIGHTUSERDATA == valuetype)
    {
        // printf("judycore.ARRAY =======\n");
        JSLI(PValue, PJArray, keystring);
        if (NULL != PValue)
        {
            void * data = lua_touserdata(L,3);
            *PValue = data;
            printf("LUA_TUSERDATA pvalue==> %p *pvalue=%p data=%p\n", PValue,*PValue,data);
            lua_pushlightuserdata(L,PJArray);
            lua_pushlightuserdata(L,PValue);
            return 2;
        }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil(L);
    return 2;
}

static int
_JLI(lua_State *L) {
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        // printf("JLI function,PJArrayis nil === \n");
        PJArray = (Pvoid_t) NULL;
    }

    // printf("jli PJArray=%p\n", PJArray);
    if ( !lua_isinteger ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    Word_t Index = lua_tointeger(L,2);
    
    short valuetype = lua_type(L, 3);
    // printf("value  type = %d \n", valuetype);

    PWord_t   PValue;// Judy array element.
    if (LUA_TSTRING == valuetype)
    {
        size_t valuelen = 0;
        const char *valuestring = lua_tolstring ( L, 3, &valuelen );
        // printf("value string = %s\n", valuestring);
        JLI(PValue, PJArray, Index);
        if (NULL != PValue)
        {
            char * desValue = JUDYMALLOC(valuelen+1);
            memset(desValue,0,valuelen+1);
            memcpy(desValue,valuestring,valuelen);

            *PValue = desValue;
            lua_pushlightuserdata(L,PJArray);
            lua_pushlightuserdata(L,PValue);
            printf("JLI string PValue=%p, *PValue=%p ,desValue=%p \n",PValue,*PValue,desValue );
            return 2;
        }
    }
    else if (LUA_TNUMBER == valuetype)
    {
        double value = lua_tonumber(L, 3);
        JLI(PValue, PJArray, Index);
        if (NULL != PValue)
        {
            *PValue = value;
            // printf("lua_number pvalue=%d ==\n",*PValue);
            lua_pushlightuserdata(L,PJArray);
            lua_pushlightuserdata(L,PValue);
            return 2;
        }
    }
    else if (LUA_TLIGHTUSERDATA == valuetype)
    {
        JLI(PValue, PJArray, Index);
        if (NULL != PValue)
        {
            void * data = lua_touserdata(L,3);
            *PValue = data;
            // printf("LUA_TUSERDATA pvalue==> %p *pvalue=%p data=%p\n", PValue,*PValue,data);
            lua_pushlightuserdata(L,PJArray);
            lua_pushlightuserdata(L,PValue);
            return 2;
        }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil(L);
    return 2;
}

static int
_JHSI(lua_State *L) {
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        // printf("JHSI function,PJArrayis nil === \n");
        PJArray = (Pvoid_t) NULL;
    }

    // printf("jsli PJArray=%p\n", PJArray);
    if ( !lua_isstring ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    size_t keylen = 0;
    const char *keystring = lua_tolstring ( L, 2, &keylen );
    // printf("key value = %s \n",keystring );
    
    short valuetype = lua_type(L, 3);
    // printf("value  type = %d \n", valuetype);

    PWord_t   PValue;// Judy array element.
    if (LUA_TSTRING == valuetype)
    {
        size_t valuelen = 0;
        const char *valuestring = lua_tolstring ( L, 3, &valuelen );
        // printf("value string = %s\n", valuestring);
        JHSI(PValue, PJArray, keystring,keylen);
        if (NULL != PValue)
        {
            char * desValue = JUDYMALLOC(valuelen+1);
            memset(desValue,0,valuelen+1);
            memcpy(desValue,valuestring,valuelen);

            *PValue = desValue;
            lua_pushlightuserdata(L,PJArray);
            lua_pushlightuserdata(L,PValue);
            return 2;
        }
    }
    else if (LUA_TNUMBER == valuetype)
    {
        double value = lua_tonumber(L, 3);
        JHSI(PValue, PJArray, keystring,keylen);
        if (NULL != PValue)
        {
            *PValue = value;
            // printf("lua_number pvalue=%d ==\n",*PValue);
            lua_pushlightuserdata(L,PJArray);
            lua_pushlightuserdata(L,PValue);
            return 2;
        }
    }
    else if (LUA_TLIGHTUSERDATA == valuetype)
    {
        JHSI(PValue, PJArray, keystring,keylen);
        if (NULL != PValue)
        {
            void * data = lua_touserdata(L,3);
            *PValue = data;
            lua_pushlightuserdata(L,PJArray);
            lua_pushlightuserdata(L,PValue);
            return 2;
        }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil(L);
    return 2;
}

static int
_JSLD(lua_State *L) {
    int      Rc_int = 0; 
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JSLI function,PJArrayis nil === \n");
    }

    // printf("jsli PJArray=%p\n", PJArray);
    if ( !lua_isstring ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushboolean(L, Rc_int);
        return 2;
    }
    size_t keylen = 0;
    const char *keystring = lua_tolstring ( L, 2, &keylen );
    // printf("key value = %s \n",keystring );
    if (keylen > 0 && keystring != NULL)
    {
        JSLD(Rc_int,PJArray,keystring)
        if (JERR == Rc_int)
        {
            printf("_JSLD out_of_memory_handling\n");
            lua_pushlightuserdata(L,PJArray);
            lua_pushnumber(L,JERR);
            return 2;
        }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushboolean(L, Rc_int);
    return 2;
}

static int
_JLD(lua_State *L) {
    int      Rc_int = 0; 
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JLD function,PJArrayis nil === \n");
    }

    // printf("jsli PJArray=%p\n", PJArray);
    if ( !lua_isinteger ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushboolean(L, Rc_int);
        return 2;
    }
    Word_t Index = lua_tointeger(L,2);

    JLD(Rc_int,PJArray,Index)
    if (JERR == Rc_int)
    {
        printf("_JLD out_of_memory_handling\n");
        lua_pushlightuserdata(L,PJArray);
        lua_pushnumber(L,JERR);
        return 2;
    }

    lua_pushlightuserdata(L,PJArray);
    lua_pushboolean(L, Rc_int);
    return 2;
}

static int
_JHSD(lua_State *L) {
    int      Rc_int = 0; 
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JSLI function,PJArrayis nil === \n");
    }

    // printf("jsli PJArray=%p\n", PJArray);
    if ( !lua_isstring ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushboolean(L, Rc_int);
        return 2;
    }
    size_t keylen = 0;
    const char *keystring = lua_tolstring ( L, 2, &keylen );
    // printf("key value = %s \n",keystring );
    if (keylen > 0 && keystring != NULL)
    {
        JHSD(Rc_int,PJArray,keystring,keylen)
        if (JERR == Rc_int)
        {
            printf("_JSLD out_of_memory_handling\n");
            lua_pushlightuserdata(L,PJArray);
            lua_pushnumber(L,JERR);
            return 2;
        }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushboolean(L, Rc_int);
    return 2;
}

static int
_JSLF(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JSLI function,PJArrayis nil === \n");
    }
    if ( !lua_isstring ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    size_t keylen = 0;
    const char *keystring = lua_tolstring ( L, 2, &keylen );
    uint8_t myBuffer[JUDY_INDEX_MAX] = {0};
    memcpy(myBuffer,keystring,keylen);

    PWord_t   PValue;                   // Judy array element.
    JSLF(PValue, PJArray, myBuffer);   // store string into array
    if (NULL != PValue)
    {
       // printf("jslg pvalue =%p value=%p\n",PValue,*PValue );
       if (argc == 2)
       {
           lua_pushlightuserdata(L,PJArray);
           lua_pushlightuserdata(L,PValue);
           lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
           return 3;
       }
       else
       {
            short dType = lua_tonumber(L,3);
            if (NUMBER == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushnumber(L,*PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
            else if (STRING == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushstring(L,(const char *) *PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
            else if (ARRAY == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,*PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
            else
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
       }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil ( L );
    return 2;
}

static int
_JSLN(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JSLI function,PJArrayis nil === \n");
    }
    
    // printf("jsli PJArray=%p\n", PJArray);
    if ( !lua_isstring ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    size_t keylen = 0;
    const char *keystring = lua_tolstring ( L, 2, &keylen );
    uint8_t myBuffer[JUDY_INDEX_MAX] = {0};
    memcpy(myBuffer,keystring,keylen);

    PWord_t   PValue;                   // Judy array element.
    JSLN(PValue, PJArray, myBuffer);   // store string into array
    if (NULL != PValue)
    {
       if (argc == 2)
       {
           lua_pushlightuserdata(L,PJArray);
           lua_pushlightuserdata(L,PValue);
           lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
           return 3;
       }
       else
       {
            short dType = lua_tonumber(L,3);
            if (NUMBER == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushnumber(L,*PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
            else if (STRING == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushstring(L,(const char *) *PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
            else if (ARRAY == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,*PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
            else
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
       }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil ( L );
    return 2;
}

static int
_JSLL(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JSLI function,PJArrayis nil === \n");
    }

    if ( !lua_isstring ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    size_t keylen = 0;
    const char *keystring = lua_tolstring ( L, 2, &keylen );
    uint8_t myBuffer[JUDY_INDEX_MAX] = {0};
    memcpy(myBuffer,keystring,keylen);

    PWord_t   PValue;                   // Judy array element.
    JSLL(PValue, PJArray, myBuffer);   // store string into array
    
    if (NULL != PValue)
    {
       if (argc == 2)
       {
           lua_pushlightuserdata(L,PJArray);
           lua_pushlightuserdata(L,PValue);
           lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
           return 3;
       }
       else
       {
            short dType = lua_tonumber(L,3);
            if (NUMBER == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushnumber(L,*PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
            else if (STRING == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushstring(L,(const char *) *PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
            else if (ARRAY == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,*PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
            else
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
       }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil ( L );
    return 2;
}

static int
_JSLP(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JSLI function,PJArrayis nil === \n");
    }

    if ( !lua_isstring ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    size_t keylen = 0;
    const char *keystring = lua_tolstring ( L, 2, &keylen );
    uint8_t myBuffer[JUDY_INDEX_MAX] = {0};
    memcpy(myBuffer,keystring,keylen);

    PWord_t   PValue;                   // Judy array element.
    JSLP(PValue, PJArray, myBuffer);   // store string into array
    
    if (NULL != PValue)
    {
       if (argc == 2)
       {
           lua_pushlightuserdata(L,PJArray);
           lua_pushlightuserdata(L,PValue);
           lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
           return 3;
       }
       else
       {
            short dType = lua_tonumber(L,3);
            if (NUMBER == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushnumber(L,*PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
            else if (STRING == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushstring(L,(const char *) *PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
            else if (ARRAY == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,*PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
            else
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,PValue);
                lua_pushlstring ( L, myBuffer, strlen(myBuffer) );
                return 3;
            }
       }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil ( L );
    return 2;
}

/*
JSL
*/

static int
_JLF(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    // printf("JLF function,PJArrayis === \n");
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JLF function,PJArrayis nil === \n");
    }
    if ( !lua_isinteger ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    Word_t Index = lua_tointeger(L,2);

    PWord_t   PValue;                   // Judy array element.
    JLF(PValue, PJArray, Index);   // store string into array
    if (NULL != PValue)
    {
       // printf("JLF pvalue =%p value=%p argc=%d\n",PValue,*PValue,argc );
       if (argc == 2)
       {
           lua_pushlightuserdata(L,PJArray);
           lua_pushlightuserdata(L,PValue);
           lua_pushinteger ( L, Index );
           return 3;
       }
       else
       {
            short dataType = lua_type(L,3);

            short dType = lua_tonumber(L,3);
            // printf("dd ==== %d  dataType=%d\n",dType,dataType );
            if (NUMBER == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushnumber(L,*PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else if (STRING == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushstring(L,(const char *) *PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else if (ARRAY == dType)
            {
                // printf(" ARRAY == dType array ====%p *pvalue=%p\n",PValue,*PValue);
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,*PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else
            {
               lua_pushlightuserdata(L,PJArray);
               lua_pushlightuserdata(L,PValue);
               lua_pushinteger ( L, Index );
               return 3;
            }
       }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil ( L );
    return 2;
}

static int
_JLN(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JLN function,PJArrayis nil === \n");
    }
    
    // printf("jsli PJArray=%p\n", PJArray);
    if ( !lua_isinteger ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    Word_t Index = lua_tointeger(L,2);

    PWord_t   PValue;                   // Judy array element.
    JLN(PValue, PJArray, Index);   // store string into array
    if (NULL != PValue)
    {
       if (argc == 2)
       {
           lua_pushlightuserdata(L,PJArray);
           lua_pushlightuserdata(L,PValue);
           lua_pushinteger ( L, Index );
           return 3;
       }
       else
       {
            short dType = lua_tonumber(L,3);
            if (NUMBER == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushnumber(L,*PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else if (STRING == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushstring(L,(const char *) *PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else if (ARRAY == dType)
            {
                // printf("JLN  is arrayp=%p, *PValue=%p \n",PValue,*PValue);
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,*PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else
            {
               lua_pushlightuserdata(L,PJArray);
               lua_pushlightuserdata(L,PValue);
               lua_pushinteger ( L, Index );
               return 3;
            }
       }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil ( L );
    return 2;
}

static int
_JLL(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JSLI function,PJArrayis nil === \n");
    }

    if ( !lua_isinteger ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    Word_t Index = lua_tointeger(L,2);

    PWord_t   PValue;                   // Judy array element.
    JLL(PValue, PJArray, Index);   // store string into array
    
    if (NULL != PValue)
    {
       if (argc == 2)
       {
           lua_pushlightuserdata(L,PJArray);
           lua_pushlightuserdata(L,PValue);
           lua_pushinteger ( L, Index );
           return 3;
       }
       else
       {
            short dType = lua_tonumber(L,3);
            if (NUMBER == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushnumber(L,*PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else if (STRING == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushstring(L,(const char *) *PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else if (ARRAY == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,*PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else
            {
               lua_pushlightuserdata(L,PJArray);
               lua_pushlightuserdata(L,PValue);
               lua_pushinteger ( L, Index );
               return 3;
            }
       }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil ( L );
    return 2;
}

static int
_JLP(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JLP function,PJArrayis nil === \n");
    }

    if ( !lua_isinteger ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    Word_t Index = lua_tointeger(L,2);

    PWord_t   PValue;                   // Judy array element.
    JLP(PValue, PJArray, Index);   // store string into array
    
    if (NULL != PValue)
    {
       if (argc == 2)
       {
           lua_pushlightuserdata(L,PJArray);
           lua_pushlightuserdata(L,PValue);
           lua_pushinteger ( L, Index );
           return 3;
       }
       else
       {
            short dType = lua_tonumber(L,3);
            if (NUMBER == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushnumber(L,*PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else if (STRING == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushstring(L,(const char *) *PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else if (ARRAY == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,*PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else
            {
               lua_pushlightuserdata(L,PJArray);
               lua_pushlightuserdata(L,PValue);
               lua_pushinteger ( L, Index );
               return 3;
            }
       }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil ( L );
    return 2;
}

static int
_JLFE(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JLF function,PJArrayis nil === \n");
    }
    if ( !lua_isinteger ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    Word_t Index = lua_tointeger(L,2);

    int      Rc_int;                   // Judy array element.
    JLFE(Rc_int, PJArray, Index);   // store string into array
    if (JERR != Rc_int)
    {
        lua_pushlightuserdata(L,PJArray);
        lua_pushinteger(L,Rc_int);
        lua_pushinteger ( L, Index );
        return 3;
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil ( L );
    return 2;
}

static int
_JLNE(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JLN function,PJArrayis nil === \n");
    }
    
    // printf("jsli PJArray=%p\n", PJArray);
    if ( !lua_isinteger ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    Word_t Index = lua_tointeger(L,2);

    int      Rc_int;                   // Judy array element.
    JLNE(Rc_int, PJArray, Index);   // store string into array
    if (JERR != Rc_int)
    {
        lua_pushlightuserdata(L,PJArray);
        lua_pushinteger(L,Rc_int);
        lua_pushinteger ( L, Index );
        return 3;
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil ( L );
    return 2;
}

static int
_JLLE(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JSLI function,PJArrayis nil === \n");
    }

    if ( !lua_isinteger ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    Word_t Index = lua_tointeger(L,2);

    int      Rc_int;                   // Judy array element.
    JLLE(Rc_int, PJArray, Index);   // store string into array
    if (JERR != Rc_int)
    {
        lua_pushlightuserdata(L,PJArray);
        lua_pushinteger(L,Rc_int);
        lua_pushinteger ( L, Index );
        return 3;
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil ( L );
    return 2;
}

static int
_JLPE(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JLP function,PJArrayis nil === \n");
    }

    if ( !lua_isinteger ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    Word_t Index = lua_tointeger(L,2);

    int      Rc_int;                   // Judy array element.
    JLPE(Rc_int, PJArray, Index);   // store string into array
    if (JERR != Rc_int)
    {
        lua_pushlightuserdata(L,PJArray);
        lua_pushinteger(L,Rc_int);
        lua_pushinteger ( L, Index );
        return 3;
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil ( L );
    return 2;
}


static int
_JLC(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JLC function,PJArrayis nil === \n");
    }
    if ( !lua_isinteger ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }
    Word_t   Rc_word = 0;
    Word_t Index = lua_tointeger(L,2);
    if (argc >= 3)
    {
        Word_t IndexEnd = lua_tointeger(L,3);
        JLC(Rc_word, PJArray, Index,IndexEnd);   // store string into array
    }
    else
    {
        JLC(Rc_word, PJArray,Index, -1);   // return all
    }
    
    lua_pushlightuserdata(L,PJArray);
    lua_pushinteger(L,Rc_word);
    return 2;
}

static int
_JLBC(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */
    Pvoid_t  PJArray = lua_touserdata(L, 1);
    if (PJArray == NULL)
    {
        printf("JLBC function,PJArrayis nil === \n");
    }
    if ( !lua_isinteger ( L, 2 ) ) {
        lua_pushlightuserdata(L,PJArray);
        lua_pushnil ( L );
        return 2;
    }

    Word_t Index = lua_tointeger(L,2);
    Word_t Nth = lua_tointeger(L,3);
    PWord_t   PValue;                   // Judy array element.
    JLBC(PValue, PJArray, Nth, Index)

    if (NULL != PValue)
    {
       if (argc == 3)
       {
           lua_pushlightuserdata(L,PJArray);
           lua_pushlightuserdata(L,PValue);
           lua_pushinteger ( L, Index );
           return 3;
       }
       else
       {
            short dType = lua_tonumber(L,4);
            if (NUMBER == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushnumber(L,*PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else if (STRING == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushstring(L,(const char *) *PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else if (ARRAY == dType)
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,*PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
            else
            {
                lua_pushlightuserdata(L,PJArray);
                lua_pushlightuserdata(L,PValue);
                lua_pushinteger ( L, Index );
                return 3;
            }
       }
    }
    lua_pushlightuserdata(L,PJArray);
    lua_pushnil ( L );
    return 2;
}

/*
JSL END
*/

static int
_Pvalue(lua_State *L) {
    int argc = lua_gettop(L);    /* number of arguments */

    // printf("pvalue type === %d\n",lua_type(L,1) );
    PWord_t   PValue = lua_touserdata(L, 1);
    if (NULL != PValue)
    {
        short dType = lua_tointeger(L, 2);
        // printf("pvalue=%p *pvalue=%p &pvalue = %p ,type =%d\n",PValue,*PValue,&PValue, dType );
        if (NUMBER == dType)
        {
            lua_pushnumber(L,*PValue);
            return 1;
        }
        else if (STRING == dType)
        {
            // printf("it's string\n");
            lua_pushstring(L,(const char *) *PValue);
            return 1;
        }
        else if (ARRAY == dType)
        {
            lua_pushlightuserdata(L,*PValue);
            return 1;
        }
        else
        {
            printf("Pvalue function \n");
            PWord_t   PPValue = *PValue;
            lua_pushlightuserdata(L,*PPValue);
        }
    }

    lua_pushnil(L);
    return 1;
}

LUALIB_API int 
luaopen_judy_core ( lua_State *L )
{
    luaL_checkversion(L);

    luaL_Reg l[] = {
        {"Judy",_new},
        {"value",_Pvalue},
        {"freestring",_freestring},
        /*JudySL*/
        {"JSLFA",_JSLFA},
        {"JSLI",_JSLI},
        {"JSLD",_JSLD},
        {"JSLG",_JSLG},
        {"JSLF",_JSLF},
        {"JSLN",_JSLN},
        {"JSLL",_JSLL},
        {"JSLP",_JSLP},
        /*JudyHS*/
        {"JHSI",_JHSI},
        {"JHSD",_JHSD},
        {"JHSG",_JHSG},
        {"JHSFA",_JHSFA},
        /*JudyL*/
        {"JLI",_JLI},
        {"JLD",_JLD},
        {"JLG",_JLG},
        {"JLC",_JLC},
        {"JLBC",_JLBC},
        {"JLFA",_JLFA},
        {"JLMU",_JLMU},
        {"JLF",_JLF},
        {"JLN",_JLN},
        {"JLL",_JLL},
        {"JLP",_JLP},
        {"JLFE",_JLFE},
        {"JLNE",_JLNE},
        {"JLLE",_JLLE},
        {"JLPE",_JLPE},
        {NULL, NULL}
    };
    luaL_newlib(L,l);

    /*array type*/
    lua_pushinteger(L, JUDYL);
    lua_setfield(L, -2, "JUDYL");

    lua_pushinteger(L, JUDYSL);
    lua_setfield(L, -2, "JUDYSL");

    lua_pushinteger(L, JUDYHS);
    lua_setfield(L, -2, "JUDYHS");

    /*data type*/
    lua_pushinteger(L, NUMBER);
    lua_setfield(L, -2, "NUMBER");

    lua_pushinteger(L, STRING);
    lua_setfield(L, -2, "STRING");

    lua_pushinteger(L, ARRAY);
    lua_setfield(L, -2, "ARRAY");

    return 1;
}
