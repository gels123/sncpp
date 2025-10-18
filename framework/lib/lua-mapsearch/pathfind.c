/**
 * pathfinder for lua
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>


static int testfunc(lua_State* L){
    printf("====testfunc====");
    return 0;
}

static const struct luaL_Reg l_methods[] = {
    { "testfunc" , testfunc },
    {NULL, NULL},
};

int luaopen_pathfind(lua_State* L) {
    luaL_checkversion(L);

    luaL_newlib(L, l_methods);

    return 1;
}

