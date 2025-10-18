/*
 *  author: gels
 *  date: 2021-12-28 20:00
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "lua.h"
#include "lauxlib.h"
#include "wrapper.h"
#include "lua-mapSearch.h"

static inline void* _toMapSearch(lua_State *L) {
    void **ppms = (void**) lua_touserdata(L, 1);
    if(ppms == NULL) {
        luaL_error(L, "lua-mapSearch.c::_toMapSearch error: must be MapSearch obj");
        return NULL;
    }
    return *ppms;
}

static int l_create(lua_State *L) 
{
    void *pms = create();
    if(pms == NULL) {
        return 0;
    }
    void **ppms = (void**) lua_newuserdata(L, sizeof(void*));
    *ppms = pms;
    lua_pushvalue(L, lua_upvalueindex(1));
    lua_setmetatable(L, -2);
    return 1;
}

static int l_release(lua_State *L)
{
    void *pms = _toMapSearch(L);
    printf("lua-mapSearch.c::l_release pms:%p\n", pms);
    release(pms);
    return 0;
}

int l_testFun(lua_State *L)
{   
    void *pms = _toMapSearch(L);
	int a = luaL_checknumber(L, 2);
    int b = luaL_checknumber(L, 3);
    printf("lua-mapSearch.c::l_testFun enter a=%d, b=%d\n", a, b);
    int num = testFun(pms, a, b);
    lua_pushinteger(L, num);
	return 1;
}

// init map, 0 for fail and 1 for success
int l_init(lua_State *L)
{   
    void *pms = _toMapSearch(L);
	unsigned int mapType = luaL_checknumber(L, 2);
    unsigned int mapSize = luaL_checknumber(L, 3);
    size_t len;
    const char* mapFile = lua_tolstring(L, 4, &len);
    size_t len2;
    const char* railwayFile = lua_tolstring(L, 5, &len2);
    unsigned int chunckSize = luaL_checknumber(L, 6);
    size_t len3;
    const char* chunckFile = lua_tolstring(L, 7, &len3);
    size_t len4;
    const char* connectFile = lua_tolstring(L, 8, &len4);
    printf("lua-mapSearch.c::l_init enter mapType=%d, mapSize=%d mapFile=%s railwayFile=%s chunckFile=%s connectFile=%s\n", mapType, mapSize, mapFile, railwayFile, chunckFile, connectFile);
    
    int num = init(pms, mapType, mapSize, mapFile, railwayFile, chunckSize, chunckFile, connectFile);
    lua_pushboolean(L, num);
	return 1;
}

int l_findPath(lua_State *L)
{
    void *pms = _toMapSearch(L);
    unsigned int x1 = luaL_checknumber(L, 2);
    unsigned int y1 = luaL_checknumber(L, 3);
    unsigned int x2 = luaL_checknumber(L, 4);
    unsigned int y2 = luaL_checknumber(L, 5);
    unsigned long long aid = luaL_checknumber(L, 6);
    float speed = luaL_checknumber(L, 7);
    float railwayTime = luaL_checknumber(L, 8);
    printf("FindPath enter, lua-mapSearch.c x1=%d y1=%d x2=%d y2=%d aid=%lld speed=%f railwayTime=%f\n", x1, y1, x2, y2, aid, speed, railwayTime);
    Path* ptr = FindPath(pms, x1, y1, x2, y2, aid, speed, railwayTime);
    if(ptr == NULL || ptr->ps == NULL) {
        printf("FindPath error, lua-mapSearch.c x1=%d y1=%d x2=%d y2=%d aid=%lld speed=%f railwayTime=%f\n", x1, y1, x2, y2, aid, speed, railwayTime);
		lua_pushnil(L);
		return 1;
	}
    printf("==findPath end count=%d\n", ptr->count);
    lua_createtable(L, ptr->count*3, 0);
    int n = 0;
    Pos* tmp = ptr->ps;
    for(int i=0; i<ptr->count; i++) {
        ++n;
        lua_pushinteger(L, tmp->x+1);
        lua_rawseti(L, -2, n);
        ++n;
        lua_pushinteger(L, tmp->y+1);
        lua_rawseti(L, -2, n);
        ++n;
        lua_pushboolean(L, tmp->railway);
        lua_rawseti(L, -2, n);
        ++tmp;
    }
    releasePath(ptr);
    return 1;
}

int l_setRailwayAid(lua_State *L)
{
    void *pms = _toMapSearch(L);
    unsigned int x = luaL_checknumber(L, 2);
    unsigned int y = luaL_checknumber(L, 3);
    unsigned long long aid = luaL_checknumber(L, 4);
    int ret = setRailwayAid(pms, x, y, aid);
    lua_pushboolean(L, ret);
    return 1;
}

int l_setFriendAid(lua_State *L)
{
    void *pms = _toMapSearch(L);
    unsigned long long aid1 = luaL_checknumber(L, 2);
    unsigned long long aid2 = luaL_checknumber(L, 3);
    int issadd = luaL_checknumber(L, 4);
    int ret = setFriendAid(pms, aid1, aid2, issadd>0);
    lua_pushboolean(L, ret);
    return 1;
}

LUALIB_API int luaopen_mapSearch(lua_State *L)
{
    luaL_checkversion(L);

    luaL_Reg l[] = {
        {"testFun", l_testFun},
        {"init", l_init},
        {"findPath", l_findPath},
        {"setRailwayAid", l_setRailwayAid},
        {"setFriendAid", l_setFriendAid},
        {NULL, NULL},
    };

    lua_createtable(L, 0, 2);

    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");

    lua_pushcfunction(L, l_release);
    lua_setfield(L, -2, "__gc");

    lua_pushcclosure(L, l_create, 1);

    return 1;
}
