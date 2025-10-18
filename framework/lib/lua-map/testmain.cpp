//
// Created by gels on 2023/1/13.
//

extern "C"
{
#include "lualib.h"
#include "lauxlib.h"
}

#include <stdio.h>
#include <iostream>
#include "MmoMap.h"

int main() {
    int *p[2];
    int a1[2] = {1, 2};
    int a2[2] = {3, 4};
    p[0] = a1;
    p[1] = a2;

    int n = 2;
    int *pnum = new int[n];
    pnum[0] = 1;
    pnum[1] = 2;
    printf("----------xxx----%d\n", p[1][1]);
    printf("----------yyy---pnum[0]=%d pnum[1]=%d\n", pnum[0], pnum[1]);


    MmoMap *pMap = new MmoMap(1200, 1200);
    printf("======xx=%d mmoArray[0]=%d, mmoArray[1]=%d\n", pMap->GetSizeY(), mmoArray[0], mmoArray[1]);
//    printf("======xx=%d mmoArray2[0]=%d, mmoArray2[1]=%d\n", pMap->GetSizeY(), mmoArray2[0], mmoArray2[1]);
    int  tolua_tarray_open (lua_State*);
    lua_State* L = luaL_newstate();
    printf("======xxx=%p\n", L);

    MmoNArray *pp = pMap->GetArray();
    printf("========kkkk====%d %d\n", pp->p[0], pp->p[1]);

    delete pMap;
    return 0;
}