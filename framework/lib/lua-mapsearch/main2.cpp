// g++ main2.cpp -o main2 -g -llua -ldl
#include <string.h>
extern "C" {
    #include "lua.h"
    #include "lauxlib.h"
    #include "lualib.h"
}

unsigned int LuaGet(struct lua_State *L, unsigned int x, unsigned int y) {
    unsigned int subzone;
    lua_getglobal(L, "get");
    lua_pushnumber(L, x);
    lua_pushnumber(L, y);
    lua_call(L, 2, 1);
    subzone = (unsigned int)lua_tonumber(L, -1);
    lua_pop(L, 1);
    return subzone;
}

void LuaGet2(struct lua_State *L) {
    while(true) {
        lua_getglobal(L, "getRailway");
        lua_call(L, 0, 11);
        int railwayid = (unsigned int)lua_tonumber(L, -11);
        int linkid1 = (unsigned int)lua_tonumber(L, -10);
        int linkid2 = (unsigned int)lua_tonumber(L, -9);
        int linkid3 = (unsigned int)lua_tonumber(L, -8);
        int linkid4 = (unsigned int)lua_tonumber(L, -7);
        int linkid5 = (unsigned int)lua_tonumber(L, -6);
        int linkid6 = (unsigned int)lua_tonumber(L, -5);
        int linkid7 = (unsigned int)lua_tonumber(L, -4);
        int linkid8 = (unsigned int)lua_tonumber(L, -3);
        int linkid9 = (unsigned int)lua_tonumber(L, -2);
        int linkid10 = (unsigned int)lua_tonumber(L, -1);
        if (railwayid <= 0) {
            break;
        } else {
            printf("===11111==railwayid=%d linkid=%d %d %d %d %d %d %d %d %d %d\n", railwayid, linkid1, linkid2, linkid3, linkid4, linkid5, linkid6, linkid7, linkid8, linkid9, linkid10);
        }
        lua_pop(L, 11);
    }
}

int main(int argc, char *argv[])
{
    int num = 100;
    int &num2 = num;
    num2 = 200;
    int *p = &num2;
    int& num3 = *p;
    printf("=============%d %d %d %d\n", num, num2, *p, num3);

    // lua_State *L = luaL_newstate();
    // luaL_openlibs(L);
    // luaL_dofile(L, "/home/share/lnx_server4/server/server/map/search/bitmap/posmap.lua");
    // /*调用C函数，这个里面会调用lua函数*/
    // for	(unsigned int i=0; i<1197;i++) {
    //     for(unsigned int j=0; j<1197;j++) {
    //         unsigned int subzone = LuaGet(L, i+1, j+1);
    //         printf("i=%d j=%d subzone=%d", i, j, subzone);
    //     }
    // }
    // lua_close(L);

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);
    luaL_dofile(L, "/home/share/lnx_server4/server/server/map/search/bitmap/EditMapRailwayServer.lua");
    LuaGet2(L);
    lua_close(L);


// nameTable={sex = "male", age=18}






// L = lua_open();
// luaL_openlibs(L);
// luaL_dofile(L, "Test.lua");
// lua_settop(L, 0);
// lua_getglobal(L, "nameTable");

// lua_pushstring(L, "sex");

// lua_gettable(L, -2);

// lua_pushstring(L, "age");

// lua_gettable(L, -3);

// int iAge = (int)lua_tointeger(L, -1);

// const char* strSex = lua_tostring(L, -2);



    return 0;
}