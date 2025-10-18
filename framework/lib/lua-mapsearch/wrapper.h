/*
 *  c调用c++接口
 *  author: gels
 *  date: 2021-12-28 20:00
 */
#ifndef _CPP_WRAPPER_H__
#define _CPP_WRAPPER_H__

#include <stdio.h>
#include <stdbool.h>
#include "lua.h"
#include "lauxlib.h"

#ifdef __cplusplus
extern "C" {
#endif

#include "lua-mapSearch.h"

//create a MapSearch instance
void* create();
//release a MapSearch instance
void release(void *pms);

// test function
int testFun(void *pms, int a, int b);

int init(void *pms, unsigned int mapType, unsigned int mapSize, const char *mapFile, const char *railwayFile, unsigned int chunckSize, const char *chunckFile, const char *connectFile);
Path* FindPath(void *pms, unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, unsigned long long aid, float speed, float railwayTime);
int setRailwayAid(void *pms, int x, int y, unsigned long long aid);
int setFriendAid(void *pms, unsigned long long aid1, unsigned long long aid2, bool isadd);

#ifdef __cplusplus
}
#endif

#endif

