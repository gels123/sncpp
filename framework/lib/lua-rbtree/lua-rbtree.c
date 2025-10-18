#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
// #include <time.h>

#include "lua.h"
#include "lauxlib.h"
#include "rbtree.h"

typedef unsigned long long ULL;

static inline rbtree* _to_rbtree(lua_State *L) {
    rbtree **rbt = lua_touserdata(L, 1);
    if(rbt == NULL)
    {
        luaL_error(L, "lua-rbtree.c: must be rbtree object");
    }
    return *rbt;
}

/*
 * 插入
 * 返回值: -1插入失败, 0重复插入, 1插入成功
 */
static int _insert(lua_State *L) {
    rbtree *rbt = _to_rbtree(L);
    if(rbt == NULL)
    {
        lua_pushnil(L);
        return 1;
    }

    double score = luaL_checknumber(L, 2);
    luaL_checktype(L, 3, LUA_TSTRING);
    size_t len;
    const char* ptr = lua_tolstring(L, 3, &len);
    
    slobj *obj = slCreateObj(ptr, len);
    slInsert(rbt, score, obj);
    return 0;

    rbtree_insert(struct rbtree *tree, void *key, void* data);

    if (!lua_isnumber(L, 1))
    {
        lua_pushnil(L);
        return 1;
    }
    uint32_t v = lua_tonumber(L, 1);
    uint32_t hash = mul_hash(v);
    // printf("lua_f_mul_hash v = %u, hash = %u\n", v, hash);
    lua_pushinteger(L, hash);
    return 1;
}

static int
_delete(lua_State *L) {
    rbtree *rbt = _to_rbtree(L);
    double score = luaL_checknumber(L, 2);
    luaL_checktype(L, 3, LUA_TSTRING);
    slobj obj;
    obj.ptr = (char *)lua_tolstring(L, 3, &obj.length);
    lua_pushboolean(L, slDelete(rbt, score, &obj));
    return 1;
}

static int
_dump(lua_State *L) {
    rbtree *rbt = _to_rbtree(L);
    slDump(rbt);
    return 0;
}

static int defaultCompare(void* key_a, void* key_b)
{
    ULL key_a_real = *(ULL*) (key_a);
    ULL key_b_real = *(ULL*) (key_b);
    if(key_a_real > key_b_real)
    {
        return 1;
    }
    else if(key_a_real == key_b_real)
    {
       return 0;
    }
    else
    {
        return -1;
    }
}

static int _new(lua_State *L)
{
    struct rbtree* tree = rbtree_init(defaultCompare);
    if(tree == NULL)
    {
        fprintf(stderr, "lua-rbtree.c: malloc tree failed\n");
        return -1;
    }
    struct rbtree **rbt = (struct rbtree**) lua_newuserdata(L, sizeof(rbtree*));
    *rbt = tree;
    lua_pushvalue(L, lua_upvalueindex(1));
    lua_setmetatable(L, -2);

    return 1;
}

static int _release(lua_State *L) {
    rbtree *rbt = _to_rbtree(L);
    printf("collect rbt:%p\n", rbt);
    slFree(rbt);
    return 0;
}

LUALIB_API int luaopen_rbtree(lua_State *L)
{
    luaL_checkversion(L);

    luaL_Reg l[] = {
        {"_insert", _insert},
        {"rbtree_lookup", lua_f_rbtree_lookup},
        {"rbtree_remove", lua_f_rbtree_remove},
        {NULL, NULL},
    };

    lua_createtable(L, 0, 2);

    luaL_newlib(L, l);
    lua_setfield(L, -2, "__index");

    lua_pushcfunction(L, _release);
    lua_setfield(L, -2, "__gc");

    lua_pushcclosure(L, _new, 1);
    return 1;
}


int lua_f_rbtree_lookup(lua_State *L)
{
    void* rbtree_lookup(struct rbtree* tree, void *key);

    if (!lua_isstring(L, 1))
    {
        lua_pushnil(L);
        return 1;
    }
    size_t vlen = 0;
    const char *str = lua_tolstring(L, 1, &vlen);
    uint32_t hash = fnv_hash((u_char *)str, vlen);
    // printf("lua_f_fnv_hash str = %s, hash = %u\n", str, hash);
    lua_pushinteger(L, hash);
    return 1;
}

int lua_f_rbtree_remove(lua_State *L)
{
    int rbtree_remove(struct rbtree* tree, void *key);

    if (!lua_isstring(L, 1))
    {
        lua_pushnil(L);
        return 1;
    }
    size_t vlen = 0;
    const char *str = lua_tolstring(L, 1, &vlen);
    uint32_t hash = fnv_hash((u_char *)str, vlen);
    // printf("lua_f_fnv_hash str = %s, hash = %u\n", str, hash);
    lua_pushinteger(L, hash);
    return 1;
}
