/*
 *  author: gels
 *  date: 2022-09-19 14:00
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "lua.h"
#include "lauxlib.h"
#include "../../luaclib/libgoogleapi.h"
// #include "libgoogleapi.h"

int ldoInit(lua_State *L)
{   
    GoString filename;
    filename.n = 0;
    filename.p = NULL;
    filename.p = luaL_checklstring(L, 1, &filename.n);
    GoString fcmfilename;
    fcmfilename.n = 0;
    fcmfilename.p = NULL;
    fcmfilename.p = luaL_checklstring(L, 2, &fcmfilename.n);
    printf("ldoInit filename=%s, n=%ld fcmfilename=%s, n=%ld\n", filename.p, filename.n, fcmfilename.p, fcmfilename.n);
    if(!filename.p || !fcmfilename.p) {
        lua_pushboolean(L, 0);
        return 1;
    }
    GoUint8 ret = doInit(filename, fcmfilename);
    lua_pushboolean(L, (int)ret);
    return 1;
}

int ldoVerify(lua_State *L)
{
    GoString packageName;
    packageName.n = 0;
    packageName.p = NULL;
    packageName.p = luaL_checklstring(L, 1, &packageName.n);
    GoString productId;
    productId.n = 0;
    productId.p = NULL;
    productId.p = luaL_checklstring(L, 2, &productId.n);
    GoString token;
    token.n = 0;
    token.p = NULL;
    token.p = luaL_checklstring(L, 3, &token.n);
    if(!packageName.p || !productId.p || !token.p) {
        lua_pushboolean(L, 0);
        lua_pushstring(L, "lua-googleapi doVerify params error");
        return 2;
    }
    struct doVerify_return ret = doVerify(packageName, productId, token);
    if(!ret.r0) {
        lua_pushboolean(L, 0);
        lua_pushstring(L, ret.r1);
        FreeString(ret.r1);
        return 2;
    } else {
        lua_pushboolean(L, 1);
        lua_pushstring(L, ret.r1);
        FreeString(ret.r1);
        return 2;
    }
}

int lsendMsgToTopic(lua_State *L)
{
    GoString topic;
    topic.n = 0;
    topic.p = NULL;
    topic.p = luaL_checklstring(L, 1, &topic.n);
    GoString title;
    title.n = 0;
    title.p = NULL;
    title.p = luaL_checklstring(L, 2, &title.n);
    GoString body;
    body.n = 0;
    body.p = NULL;
    body.p = luaL_checklstring(L, 3, &body.n);
    if(!topic.p || !title.p || !body.p) {
        lua_pushboolean(L, 0);
        return 1;
    }
    GoUint8 ok = sendMsgToTopic(topic, title, body);
    lua_pushboolean(L, ok);
    return 1;
}

int lsendMsgToToken(lua_State *L)
{
    GoString token;
    token.n = 0;
    token.p = NULL;
    token.p = luaL_checklstring(L, 1, &token.n);
    GoString title;
    title.n = 0;
    title.p = NULL;
    title.p = luaL_checklstring(L, 2, &title.n);
    GoString body;
    body.n = 0;
    body.p = NULL;
    body.p = luaL_checklstring(L, 3, &body.n);
    if(!token.p || !title.p || !body.p) {
        lua_pushboolean(L, 0);
        return 1;
    }
    GoUint8 ok = sendMsgToToken(token, title, body);
    lua_pushboolean(L, ok);
    return 1;
}

int lsubscribe(lua_State *L)
{
    GoString topic;
    topic.n = 0;
    topic.p = NULL;
    topic.p = luaL_checklstring(L, 1, &topic.n);
    GoInt len = luaL_checknumber(L, 2);
    if(len <= 0) {
        lua_pushboolean(L, 0);
        printf("lsubscribe error1\n");
        return 1;
    }
    GoString data[len];
    for (int i = 0; i < len; i++) {
        lua_pushnumber(L, i+1);
        lua_gettable(L, -2);
        data[i].n = 0;
        data[i].p = NULL;
        data[i].p = luaL_checklstring(L, -1, &(data[i].n));
        lua_pop(L, 1);
        if(!data[i].p) {
            lua_pushboolean(L, 0);
            printf("lsubscribe error2\n");
            return 1;
        }
        printf("lsubscribe topic=%s data[%d]=%s\n", topic.p, i, data[i].p);
    }
    GoSlice tokens = {data, len, len};
    GoUint8 ok = subscribe(topic, tokens);
    lua_pushboolean(L, ok);
    return 1;
}

int lunsubscribe(lua_State *L)
{
    GoString topic;
    topic.n = 0;
    topic.p = NULL;
    topic.p = luaL_checklstring(L, 1, &topic.n);
    GoInt len = luaL_checknumber(L, 2);
    if(len <= 0) {
        lua_pushboolean(L, 0);
        printf("lunsubscribe error\n");
        return 1;
    }
    GoString data[len];
    for (int i = 0; i < len; i++) {
        lua_pushnumber(L, i+1);
        lua_gettable(L, -2);
        data[i].n = 0;
        data[i].p = NULL;
        data[i].p = luaL_checklstring(L, -1, &(data[i].n));
        lua_pop(L, 1);
        if(!data[i].p) {
            lua_pushboolean(L, 0);
            printf("lunsubscribe error2\n");
            return 1;
        }
        printf("lunsubscribe topic=%s data[%d]=%s\n", topic.p, i, data[i].p);
    }
    GoSlice tokens = {data, len, len};
    GoUint8 ok = unsubscribe(topic, tokens);
    lua_pushboolean(L, ok);
    return 1;
}

LUALIB_API int luaopen_luagoogleapi(lua_State *L)
{
    luaL_Reg reg[] = {
        {"doInit", ldoInit},
        {"doVerify", ldoVerify},
        {"sendMsgToTopic", lsendMsgToTopic},
        {"sendMsgToToken", lsendMsgToToken},
        {"subscribe", lsubscribe},
        {"unsubscribe", lunsubscribe},
        {NULL, NULL}
    };
    luaL_newlib(L, reg);
    return 1;
}
