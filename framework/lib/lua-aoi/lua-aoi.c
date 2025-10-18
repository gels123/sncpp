#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "lua.h"
#include "lauxlib.h"

#include "aoi.h"

#define UNUSED(x) (void)(x)

extern float AOI_RADIS;
extern float AOI_RADIS2;

struct alloc_cookie {
    int count;
    int max;
    int current;
};

struct user_data {
    int idx;
    lua_State *L;
};

static void
message_cb(void *ud, uint32_t watcher, uint32_t marker) {
    //获取数据
    printf("message p=%p, w= %d,m=%d \n", ud, watcher, marker);
    uint32_t data[2] = {watcher, marker};
    struct user_data * pud = (struct user_data *) ud;
    lua_State *L = pud->L;
    if(pud->idx == 1)
    {
        lua_newtable(L);
    }
    for(int i = 0; i < 2; i++ )
    {
        lua_pushinteger(L, data[i]);
        lua_rawseti(L, -2, pud->idx);
        pud->idx = pud->idx + 1;
    }
}

static inline struct aoi_space*
_to_space(lua_State *L) {
    struct aoi_space **_cspace = lua_touserdata(L, 1);
    if(_cspace==0) {
        luaL_error(L, "must be conhash_s object");
    }
    return *_cspace;
}

static void
updateobj(lua_State *L) {
    luaL_checktype(L, 2, LUA_TNUMBER); //ID
    luaL_checktype(L, 3, LUA_TSTRING); //mode
    luaL_checktype(L, 4, LUA_TNUMBER); //x
    luaL_checktype(L, 5, LUA_TNUMBER); //y
    luaL_checktype(L, 6, LUA_TNUMBER); //z
    struct aoi_space *space = _to_space(L);
    unsigned int ID = luaL_checkinteger(L, 2);
    const char* mode = (const char*) lua_tostring(L, 3);
    //printf("space= %p, id =%d,mode =%s\n",space, ID,mode);
    float x,y,z;
    x = luaL_checknumber(L, 4);
    y = luaL_checknumber(L, 5);
    z = luaL_checknumber(L, 6);
    //printf("a x=%f,y=%f,z=%f\n",x,y,z);
    float pos[3] = {
        x,y,z
    };
    aoi_update(space, ID, mode, pos);
    lua_pushboolean(L,1);
}

static int
_add(lua_State *L) {
    updateobj(L);
    return 1;
}

static int
_delete(lua_State *L) {
    updateobj(L);
    return 1;
}

static int
_update(lua_State *L) {
    updateobj(L);
    return 1;
}

static int
_message(lua_State *L) {
    struct aoi_space *space = _to_space(L);
    struct user_data ud = {1, L};
    aoi_message(space, message_cb, &ud);
    if(1 == ud.idx)
        lua_pushnil(L);
    return 1;
}

static int
_setRadis(lua_State *L) {
    luaL_checktype(L, 2, LUA_TNUMBER);
    struct aoi_space *space = _to_space(L);
    UNUSED(space);
    AOI_RADIS = luaL_checknumber(L, 2);
    AOI_RADIS2 = AOI_RADIS * AOI_RADIS;
    return 0;   
}

static int
_new(lua_State *L) {
    struct aoi_space * pspace = aoi_new();
    struct aoi_space **_cspace = (struct aoi_space**) lua_newuserdata(L, sizeof(struct aoi_space*));
    *_cspace = pspace;
    lua_pushvalue(L, lua_upvalueindex(1));
    lua_setmetatable(L, -2);
    return 1;
}

static int
_release(lua_State *L) {
    struct aoi_space *space = _to_space(L);
    aoi_release(space);
    space = 0;
    return 0;
}

int luaopen_aoi_core(lua_State *L) {
    luaL_Reg l[] = {
        {"add", _add},
        {"delete", _delete},
        {"update", _update},
        {"message", _message},
        {"setRadis", _setRadis},
        {NULL, NULL}
    };

    AOI_RADIS2 = AOI_RADIS * AOI_RADIS;

    lua_createtable(L, 0, 2);

    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, _release);
    lua_setfield(L, -2, "__gc");

    lua_pushcclosure(L, _new, 1);
    return 1;
}
