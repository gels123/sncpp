#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#include <time.h>

#include "lua.h"
#include "lauxlib.h"

#include "link-aoi.h"

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
    printf("lua-aoi-link enter_func self=%d other=%d\n", self, other);
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
    printf("lua-aoi-link leave_func self=%d other=%d\n", self, other);
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
//    printf("lua-aoi-link enter_func self=%d other=%d\n", self, other);
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
        luaL_error(L, "lua-aoi-link error: must be aoi_context object");
    }
    return *pctx;
}

static int create_entity_(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    int objid = luaL_checknumber(L, 2);
    int x = luaL_checknumber(L, 3);
    int z = luaL_checknumber(L, 4);

    struct user_data2 * ud = (struct user_data2 *) ctx->ud;
    ud->b = ud->i[0] = ud->i[1] = 0;
    ud->L = L;

    struct aoi_object* obj = create_aoi_object(ctx, objid);
    int r = create_entity(ctx, obj, x, z);
    if (r < 0) {
        lua_pushinteger(L, r);
        return 1;
    } else {
        //printf("create_entity_ r=%d obj=%p\n", r, (void*)obj);
        if (ud->b) {
            lua_pushinteger(L, 0);
            lua_insert(L, -3);
            lua_pushlightuserdata(L, obj);
            lua_insert(L, -3);
            return 4;
        } else {
            lua_pushinteger(L, 0);
            lua_pushlightuserdata(L, obj);
            return 2;
        }
    }
}

static int create_trigger_(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    int objid = luaL_checknumber(L, 2);
    int x = luaL_checknumber(L, 3);
    int z = luaL_checknumber(L, 4);
    int range = luaL_checknumber(L, 5);

    struct user_data2 * ud = (struct user_data2 *) ctx->ud;
    ud->b = ud->i[0] = ud->i[1] = 0;
    ud->L = L;

    struct aoi_object* obj = create_aoi_object(ctx, objid);
    int r = create_trigger(ctx, obj, x, z, range);
    if (r < 0) {
        lua_pushinteger(L, r);
        return 1;
    } else {
        //printf("create_trigger_ r=%d obj=%p\n", r, (void*)obj);
        if (ud->b) {
            lua_pushinteger(L, 0);
            lua_insert(L, -3);
            lua_pushlightuserdata(L, obj);
            lua_insert(L, -3);
            return 4;
        } else {
            lua_pushinteger(L, 0);
            lua_pushlightuserdata(L, obj);
            return 2;
        }
    }
}

static int move_entity_(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    struct aoi_object* obj = lua_touserdata(L, 2);
    //printf("move_entity_ obj=%p\n", (void*)obj);
    int x = luaL_checknumber(L, 3);
    int z = luaL_checknumber(L, 4);

    struct user_data2 * ud = (struct user_data2 *) ctx->ud;
    ud->b = ud->i[0] = ud->i[1] = 0;
    ud->L = L;

    move_entity(ctx, obj, x, z);
    return ud->b;
}

static int move_trigger_(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    struct aoi_object* obj = lua_touserdata(L, 2);
    //printf("move_trigger_ obj=%p\n", (void*)obj);
    int x = luaL_checknumber(L, 3);
    int z = luaL_checknumber(L, 4);

    struct user_data2 * ud = (struct user_data2 *) ctx->ud;
    ud->b = ud->i[0] = ud->i[1] = 0;
    ud->L = L;

    move_trigger(ctx, obj, x, z);
    return ud->b;
}

static int delete_entity_(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    struct aoi_object* obj = lua_touserdata(L, 2);

    struct user_data2 * ud = (struct user_data2 *) ctx->ud;
    ud->b = ud->i[0] = ud->i[1] = 0;
    ud->L = L;

    delete_entity(ctx, obj, 1);
    return ud->b;
}

static int delete_trigger_(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    struct aoi_object* obj = lua_touserdata(L, 2);

    struct user_data2 * ud = (struct user_data2 *) ctx->ud;
    ud->b = ud->i[0] = ud->i[1] = 0;
    ud->L = L;

    delete_trigger(ctx, obj);
    return ud->b;
}

static int get_witness_(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    struct aoi_object* obj = lua_touserdata(L, 2);
    //printf("get_witness_ obj=%p\n", (void*)obj);
    struct user_data ud = {0, L};
    get_witness(ctx, obj, cb_func, &ud);
    if (ud.i) {
        return 1;
    } else {
        return 0;
    }
}

static int get_visible_(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    struct aoi_object* obj = lua_touserdata(L, 2);
    //printf("get_visible_ obj=%p\n", (void*)obj);
    struct user_data ud = {0, L};
    get_visible(ctx, obj, cb_func, &ud);
    if (ud.i) {
        return 1;
    } else {
        return 0;
    }
}

static int _new(lua_State *L) {
    struct user_data2 *ud = malloc(sizeof(*ud));
    memset(ud, 0, sizeof(*ud));
    struct aoi_context *ctx = create_aoi_ctx(enter_func, leave_func, ud);
    struct aoi_context **pctx = (struct aoi_context **) lua_newuserdata(L, sizeof(struct aoi_context*));
    *pctx = ctx;
    lua_pushvalue(L, lua_upvalueindex(1));
    lua_setmetatable(L, -2);
    //printf("lua-aoi-link _new, ctx=%p\n", (void*)ctx);
    return 1;
}

static int _release(lua_State *L) {
    struct aoi_context *ctx = _to_context(L);
    if (ctx->ud) {
        free(ctx->ud);
        ctx->ud = NULL;
    }
    release_aoi_ctx(ctx);
    ctx = NULL;
    return 0;
}

int luaopen_aoilink(lua_State *L) {
    luaL_Reg l[] = {
        {"create_entity", create_entity_},
        {"create_trigger", create_trigger_},
        {"move_entity", move_entity_},
        {"move_trigger", move_trigger_},
        {"delete_entity", delete_entity_},
        {"delete_trigger", delete_trigger_},
        {"get_witness", get_witness_},
        {"get_visible", get_visible_},
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
