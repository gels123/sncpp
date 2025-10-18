
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"

static unsigned int num_escape_sql_str2(unsigned char *dst, unsigned char *src, size_t size)
{
    unsigned int n =0;
    while (size) {
        /* the highest bit of all the UTF-8 chars
         * is always 1 */
        if ((*src & 0x80) == 0) {
            switch (*src) {
                case '\0':
                case '\b':
                case '\n':
                case '\r':
                case '\t':
                case 26:  /* \Z */
                case '\\':
                case '\'':
                case '"':
                    n++;
                    break;
                default:
                    break;
            }
        }
        src++;
        size--;
    }
    return n;
}
static unsigned char*
escape_sql_str2(unsigned char *dst, unsigned char *src, size_t size)
{
    
      while (size) {
        if ((*src & 0x80) == 0) {
            switch (*src) {
                case '\0':
                    *dst++ = '\\';
                    *dst++ = '0';
                    break;
                    
                case '\b':
                    *dst++ = '\\';
                    *dst++ = 'b';
                    break;
                    
                case '\n':
                    *dst++ = '\\';
                    *dst++ = 'n';
                    break;
                    
                case '\r':
                    *dst++ = '\\';
                    *dst++ = 'r';
                    break;
                    
                case '\t':
                    *dst++ = '\\';
                    *dst++ = 't';
                    break;
                    
                case 26:
                    *dst++ = '\\';
                    *dst++ = 'Z';
                    break;
                    
                case '\\':
                    *dst++ = '\\';
                    *dst++ = '\\';
                    break;
                    
                case '\'':
                    *dst++ = '\\';
                    *dst++ = '\'';
                    break;
                    
                case '"':
                    *dst++ = '\\';
                    *dst++ = '"';
                    break;
                    
                default:
                    *dst++ = *src;
                    break;
            }
        } else {
            *dst++ = *src;
        }
        src++;
        size--;
    } /* while (size) */
    
    return  dst;
}




static int
lua_quote_sql_str(lua_State *L)
{
    size_t                   len, dlen, escape;
    unsigned char                  *p;
    unsigned char                  *src, *dst;
    
    if (lua_gettop(L) != 1) {
        return luaL_error(L, "expecting one argument");
    }
    
    src = (unsigned char *) luaL_checklstring(L, 1, &len);
    
    if (len == 0) {
        dst = (unsigned char *) "''";
        dlen = sizeof("''") - 1;
        lua_pushboolean(L,0);
        lua_pushlstring(L, (char *) dst, dlen);
        return 2;
    }
    
    escape = num_escape_sql_str2(NULL, src, len);
    
    dlen = sizeof("''") - 1 + len + escape;
    // p = malloc(dlen);
    p = lua_newuserdata(L,dlen);

    dst = p;
    
    *p++ = '\'';
    
    if (escape == 0) {
        memcpy(p, src, len);
        p+=len;
    } else {
        p = (unsigned char *) escape_sql_str2(p, src, len);
    }
    
    *p++ = '\'';
    
    if (p != dst + dlen) {
        return luaL_error(L, "quote sql string error");
    }
    
    unsigned int reallen = p - dst;
    if(reallen > 2)
    {
        lua_pushboolean(L,1);
        lua_pushlstring(L, (char *) dst + 1, reallen - 2);
    }
    else
    {
        printf("syx lua_quote_sql_str error= %d\n",reallen );
        lua_pushboolean(L,0);
        lua_pushlstring(L, (char *) dst, reallen);
    }
    // free(dst);
    return 2;
}

LUALIB_API int 
luaopen_newmysqlaux( lua_State *L )
{
    luaL_checkversion(L);

    luaL_Reg l[] = {
        {"quote_sql_str",lua_quote_sql_str},
        {NULL, NULL}
    };
    luaL_newlib(L,l);

    return 1;
}

