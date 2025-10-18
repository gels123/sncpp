#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "lua.h"
#include "lauxlib.h"

#include "simple-aoi.h"

#define UNUSED(x) (void)(x)

struct user_data {
    int i;
    lua_State *L;
};

struct user_data2 {
    int b;
    int i[2];
    lua_State *L;
};

static void enter_func(int self, int other, void* ud) {
    //printf("aoi-simple enter_func self=%d other=%d\n", self, other);
    struct user_data2 * pud = (struct user_data2 *) ud;
    lua_State *L = pud->L;
    if(pud->b == 0) {
        pud->b = 2;
        lua_newtable(L);
        lua_newtable(L);
    }
    pud->i[0] = pud->i[0] + 1;
    lua_pushinteger(L, self);
    lua_rawseti(L, -3, pud->i[0]);
    pud->i[0] = pud->i[0] + 1;
    lua_pushinteger(L, other);
    lua_rawseti(L, -3, pud->i[0]);
}

static void leave_func(int self, int other, void* ud) {
    //printf("aoi-simple leave_func self=%d other=%d\n", self, other);
    struct user_data2 * pud = (struct user_data2 *) ud;
    lua_State *L = pud->L;
    if(pud->b == 0) {
        pud->b = 2;
        lua_newtable(L);
        lua_newtable(L);
    }
    pud->i[1] = pud->i[1] + 1;
    lua_pushinteger(L, self);
    lua_rawseti(L, -2, pud->i[1]);
    pud->i[1] = pud->i[1] + 1;
    lua_pushinteger(L, other);
    lua_rawseti(L, -2, pud->i[1]);
}

static void cb_func(int self, int other, void* ud) {
    //printf("aoi-simple enter_func self=%d other=%d\n", self, other);
    struct user_data * pud = (struct user_data *) ud;
    lua_State *L = pud->L;
    if (!pud->i) {
        lua_newtable(L);
    }
    pud->i++;
    lua_pushinteger(L, other);
    lua_rawseti(L, -2, pud->i);
}

static inline struct aoi_context* _to_context(lua_State *L) {
    struct aoi_context **pctx = lua_touserdata(L, 1);
    if(pctx == NULL) {
        luaL_error(L, "aoi-simple error: must be aoi_context object");
    }
    return *pctx;
}

static int aoi_enter_(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    int objid = luaL_checknumber(L, 2);
    int x = luaL_checknumber(L, 3);
    int z = luaL_checknumber(L, 4);
    int layer = luaL_checknumber(L, 5);
    struct user_data2 ud = {0, {0, 0}, L};
    int r = aoi_enter(ctx, objid, x, z, layer, &ud);
    if (r < 0) {
        lua_pushinteger(L, r);
        return 1;
    } else {
        if (ud.b) {
            lua_pushinteger(L, r);
            lua_insert(L, -3);
            return 3;
        } else {
            lua_pushinteger(L, r);
            return 1;
        }
    }
}

static int aoi_leave_(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    int id = luaL_checknumber(L, 2);
    struct user_data2 ud = {0, {0, 0}, L};
    int r = aoi_leave(ctx, id, &ud);
    if (r < 0) {
        return 0;
    } else {
        return ud.b;
    }
}

static int aoi_update_(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    int id = luaL_checknumber(L, 2);
    int x = luaL_checknumber(L, 3);
    int z = luaL_checknumber(L, 4);
    struct user_data2 ud = {0, {0, 0}, L};
    int r = aoi_update(ctx, id, x, z, &ud);
    if (r < 0) {
        lua_pushinteger(L, r);
        return 1;
    } else {
        if (ud.b) {
            lua_pushinteger(L, r);
            lua_insert(L, -3);
            return 3;
        } else {
            lua_pushinteger(L, r);
            return 1;
        }
    }
}

static int get_witness_(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    int id = luaL_checknumber(L, 2);
    //printf("get_witness_ id=%d\n", id);
    struct user_data ud = {0, L};
    get_witness(ctx, id, cb_func, &ud);
    if (ud.i) {
        return 1;
    } else {
        return 0;
    }
}

static int get_visible_(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    int id = luaL_checknumber(L, 2);
    //printf("get_visible_ id=%d\n", id);
    struct user_data ud = {0, L};
    get_visible(ctx, id, cb_func, &ud);
    if (ud.i) {
        return 1;
    } else {
        return 0;
    }
}

static int aoi_error_(lua_State *L) {
    luaL_checktype(L, 2, LUA_TNUMBER);
    struct aoi_context *ctx = _to_context(L);
    UNUSED(ctx);
    int no = luaL_checknumber(L, 2);
    const char* err_msg = aoi_error(no);
    if(err_msg) {
        lua_pushstring(L, err_msg);
    } else {
        lua_pushnil(L);
    }
    return 1;
}

static int _new(lua_State *L) {
    int width = luaL_checknumber(L, 1);     // 地图宽x
    int height = luaL_checknumber(L, 2);    // 地图高z
    int cell = luaL_checknumber(L, 3);      // 地图格宽高
    int range = luaL_checknumber(L, 4);     // 视野范围
    struct aoi_context *ctx = aoi_create(width, height, cell, range, 5000, enter_func, leave_func);
    struct aoi_context **pctx = (struct aoi_context **) lua_newuserdata(L, sizeof(struct aoi_context*));
    *pctx = ctx;
    lua_pushvalue(L, lua_upvalueindex(1));
    lua_setmetatable(L, -2);
    //printf("aoi-simple _new, width=%d height=%d cell=%d range=%d ctx=%p\n", width, height, cell, range, ctx);
    return 1;
}

static int _release(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    aoi_release(ctx);
    ctx = NULL;
    return 0;
}

int luaopen_aoisimple(lua_State *L) {
    luaL_Reg l[] = {
        {"aoi_enter", aoi_enter_},
        {"aoi_leave", aoi_leave_},
        {"aoi_update", aoi_update_},
        {"get_witness", get_witness_},
        {"get_visible", get_visible_},
        {"aoi_error", aoi_error_},
        {NULL, NULL}
    };
    lua_createtable(L, 0, 2);
    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, _release);
    lua_setfield(L, -2, "__gc");

    lua_pushcclosure(L, _new, 1);
    return 1;
}
