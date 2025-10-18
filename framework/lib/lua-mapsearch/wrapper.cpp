#include <stdio.h>
#include <stdlib.h>
#include "wrapper.h"
#include "mapSearch.h"
#include <list>
extern "C" {
    #include "lua.h"
    #include "lualib.h"
    #include "lauxlib.h"
}
 
using namespace alg;

#ifdef __cplusplus
extern "C" {
#endif

//create a MapSearch instance
void* create()
{
	MapSearch *p = new MapSearch();
	printf("wrapper.cp::create p=%p\n", (void*)p);
	return (void*) p;
}

void release(void *pms)
{
	if(pms == NULL) {
		printf("wrapper.cpp::release error: pms == 0");
		return;
	}
	MapSearch *p = (MapSearch *) pms;
	delete p;
}

// testFun function
int testFun(void *pms, int a, int b)
{	
	if(pms == NULL) {
		printf("wrapper.cpp::testFun error: pms == 0");
		return 0;
	}
	MapSearch *p = (MapSearch *) pms;
	if(p == NULL) {
		printf("wrapper.cpp::init error: p == 0");
		return 0;
	}
	printf("wrapper.cpp::testFun p=%p a=%d b=%d\n", (void*)p, a, b);
    return p->testFun(a, b);
}

int init(void *pms, unsigned int mapType, unsigned int mapSize, const char *mapFile, const char *railwayFile, unsigned int chunckSize, const char *chunckFile, const char *connectFile)
{
	if(pms == NULL) {
		printf("wrapper.cpp::init error1: pms == 0");
		return 0;
	}
	MapSearch *p = (MapSearch *) pms;
	if(p == NULL) {
		printf("wrapper.cpp::init error2: p == 0");
		return 0;
	}
	return p->Init(mapType, mapSize, mapFile, railwayFile, chunckSize, chunckFile, connectFile);
}

Path* FindPath(void *pms, unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, unsigned long long aid, float speed, float railwayTime)
{
	if(pms == NULL) {
		printf("FindPath error1, wrapper.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld speed=%f railwayTime=%f\n", x1, y1, x2, y2, aid, speed, railwayTime);
		return NULL;
	}
	MapSearch *p = (MapSearch *) pms;
	if(p == NULL) {
		printf("FindPath error2, wrapper.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld speed=%f railwayTime=%f\n", x1, y1, x2, y2, aid, speed, railwayTime);
		return NULL;
	}
	return p->FindPath(x1, y1, x2, y2, speed, railwayTime);
}

int setRailwayAid(void *pms, int x, int y, unsigned long long aid) {
	if(pms == NULL) {
		printf("setRailwayAid error1, wrapper.cpp x=%d y=%d aid=%lld\n", x, y, aid);
		return 0;
	}
	MapSearch *p = (MapSearch *) pms;
	if(p == NULL) {
		printf("setRailwayAid error2, wrapper.cpp x=%d y=%d aid=%lld\n", x, y, aid);
		return 0;
	}
	return p->SetRailwayAid(x, y, aid);
}

int setFriendAid(void *pms, unsigned long long aid1, unsigned long long aid2, bool isadd) {
	if(pms == NULL) {
		printf("setFriendAid error1, wrapper.cpp aid1=%lld aid2=%lld\n", aid1, aid2);
		return 0;
	}
	MapSearch *p = (MapSearch *) pms;
	if(p == NULL) {
		printf("setFriendAid error2, wrapper.cpp aid1=%lld aid2=%lld\n", aid1, aid2);
		return 0;
	}
	return p->SetFriendAid(aid1, aid2, isadd);
}

#ifdef __cplusplus
}
#endif
