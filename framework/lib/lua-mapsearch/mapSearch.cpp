//
//  mapSearch.cpp
//
//  Created by GeLiusheng on 2021/12/28.
//  Copyright © 2021年 Liusheng Ge. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <string.h>
#include "mapSearch.h"
extern "C" {
    #include "lua.h"
    #include "lualib.h"
    #include "lauxlib.h"
}

#define optimize
#define dbg

using namespace alg;

int LuaGet(struct lua_State *L, unsigned int x, unsigned int y) {
    unsigned int subzone;
    lua_getglobal(L, "get");
    lua_pushnumber(L, x);
    lua_pushnumber(L, y);
    lua_call(L, 2, 1);
    subzone = (int)lua_tonumber(L, -1);
    lua_pop(L, 1);
    return subzone;
}

void LuaGet2(struct lua_State *L, std::map<int, std::vector<Railway*>*> *p, std::map<int, unsigned long long> *pp) {
    while(true) {
        lua_getglobal(L, "getRailway");
        lua_call(L, 0, 3);
        int id1 = (int)lua_tonumber(L, -3);
        int id2 = (int)lua_tonumber(L, -2);
        float distance = (unsigned int)lua_tonumber(L, -1);
        lua_pop(L, 3);
        if (id1 <= 0) {
            break;
        } else {
            // printf("===LuaGet2==id1=%d id2=%d distance=%d\n", id1, id2, distance);
            int y1= ((int)id1/AStar::MOD-1), x1 = (id1%AStar::MOD-1);
            id1 = y1 * AStar::MOD + x1;
            int y2 = ((int)id2/AStar::MOD-1), x2 = (id2%AStar::MOD-1);
            id2 = y2 * AStar::MOD + x2;
            auto it1 = p->find(id1);
            if(it1 != p->end()) {
                std::vector<Railway*>* vec = it1->second;
                if(id2 != id1) {
                    Railway* p3 = new Railway(id2, x2, y2);
                    vec->push_back(p3);
                }
            } else {
                std::vector<Railway*>* vec = new std::vector<Railway*>();
                if(id2 != id1) {
                    Railway* p3 = new Railway(id2, x2, y2);
                    vec->push_back(p3);
                }
                p->insert(std::make_pair(id1, vec));
            }
            auto it2 = p->find(id2);
            if(it2 != p->end()) {
                std::vector<Railway*>* vec = it2->second;
                if(id1 != id2) {
                    Railway* p3 = new Railway(id1, x1, y1);
                    vec->push_back(p3);
                }
            } else {
                std::vector<Railway*>* vec = new std::vector<Railway*>();
                if(id1 != id2) {
                    Railway* p3 = new Railway(id1, x1, y1);
                    vec->push_back(p3);
                }
                p->insert(std::make_pair(id2, vec));
            }
            if(pp->find(id1) == pp->end()) {
                pp->insert(std::make_pair(id1, 0));
            }
            if(pp->find(id2) == pp->end()) {
                pp->insert(std::make_pair(id2, 0));
            }
            // float truedistance = sqrtf((x2-x1) * (x2-x1) + (y2-y1)*(y2-y1));
            // int maxchunck = max(abs((int)AStar::xToChunckX(x2) - (int)AStar::xToChunckX(x1)), abs((int)AStar::xToChunckX(y2) - (int)AStar::xToChunckX(y1)));
            // printf("==LuaGet2==x1=%d y1=%d x2=%d y2=%d truedistance=%f distance=%f rate=%f maxchunck=%d\n", x1, y1, x2, y2, truedistance, distance, truedistance/(distance/xishu), maxchunck);
        }
    }
    //打印
    #ifdef dbg
    for(auto it = p->begin();it!=p->end();it++) {
        int id1 = it->first;
        auto it2 = it->second;
        printf("id1=%d ==>", id1);
        for(auto it3=it2->begin();it3!=it2->end();it3++) {
            auto it4 = *it3;
            printf("[%d,%f]", it4->id, 0.0);
        }
        printf("\n");
    }
    #endif
}

void LuaGet3(struct lua_State *L, std::map<int, std::map<int, std::vector<Graph*>*>*> &zoneconnect, Array2D<Graph> &p_mapGrid) {
    while(true) {
        lua_getglobal(L, "getZoneConnect");
        lua_call(L, 0, 7);
        int zone1 = (int)lua_tonumber(L, -7);
        int x1 = (int)lua_tonumber(L, -6)-1;
        int y1 = (int)lua_tonumber(L, -5)-1;
        int zone2 = (int)lua_tonumber(L, -4);
        int x2 = (int)lua_tonumber(L, -3)-1;
        int y2 = (int)lua_tonumber(L, -2)-1;
        int wailway = (int)lua_tonumber(L, -1);
        lua_pop(L, 7);
        if (zone1 <= 0) {
            break;
        } else {
            // printf("===LuaGet3==zone1=%d x1=%d y1=%d zone2=%d x2=%d y2=%d wailway=%d\n", zone1, x1, y1, zone2, x2, y2, wailway);
            auto it = zoneconnect.find(zone1);
            if(it == zoneconnect.end()) {
                zoneconnect.insert(std::make_pair(zone1, new std::map<int, std::vector<Graph*>*>()));
            }
            it = zoneconnect.find(zone1);
            std::map<int, std::vector<Graph*>*> *mm = it->second;
            auto it2 = mm->find(zone2);
            if(it2 == mm->end()) {
                mm->insert(std::make_pair(zone2, new std::vector<Graph*>()));
            }
            it2 = mm->find(zone2);
            (*it2).second->push_back(&p_mapGrid(y1, x1));
            //
            it = zoneconnect.find(zone2);
            if(it == zoneconnect.end()) {
                zoneconnect.insert(std::make_pair(zone2, new std::map<int, std::vector<Graph*>*>()));
            }
            it = zoneconnect.find(zone2);
            mm = it->second;
            it2 = mm->find(zone1);
            if(it2 == mm->end()) {
                mm->insert(std::make_pair(zone1, new std::vector<Graph*>()));
            }
            it2 = mm->find(zone1);
            (*it2).second->push_back(&p_mapGrid(y2, x2));
        }
    }
    //打印
    #ifdef false //std::map<int, std::map<int, std::vector<Graph*>*>*> zoneconnect;
        for(auto it = zoneconnect.begin();it!=zoneconnect.end();it++) {
            std::map<int, std::vector<Graph*>*>* it2 = it->second;
            for(auto it3=it2->begin();it3!=it2->end();it3++) {
                std::vector<Graph*>* it4 = it3->second;
                for(auto it5=it4->begin(); it5!=it4->end(); it5++) {
                    printf("zone1=%d ", it->first);
                    printf("zone2=%d ", it3->first);
                    printf("x=%d y=%d \n", (*it5)->x, (*it5)->y);
                }
            }
        }
    #endif
}

MapSearch::MapSearch()
{
    m_mapType = 0;
    m_mapSize = 0;
    memset(m_mapFile, '\0', sizeof(m_mapFile));
    p_mapGrid = NULL;
    p_railway = NULL;
    p_railwayaid = NULL;
    p_friendaid = NULL;
    p_astar = NULL;
    m_chunckSize = 0;
    p_chunckGrid = NULL;
    p_chunckrailway = NULL;
    p_chunckrailwayaid = NULL;
    p_chunckastar = NULL;
    m_clear1.clear();
    m_clear2.clear();
    m_ptr1.clear();
    m_ptr2.clear();
    zoneconnect.clear();
    printf("MapSearch::MapSearch() %ld %ld %ld\n", m_ptr1.size(), m_ptr2.size(), zoneconnect.size());
}

MapSearch::~MapSearch()
{
    // printf("MapSearch::~MapSearch()\n");
    if(p_mapGrid != NULL) {
        delete p_mapGrid;
        p_mapGrid = NULL;
    }
    if(p_railway != NULL) {
        for(auto it = p_railway->begin(); it != p_railway->end(); it++) {
            auto *vec = it->second;
            if(vec != NULL) {
                for(auto it2=vec->begin();it2!=vec->end();it2++) {
                    Railway* p2 = *it2;
                    if(p2 != NULL) {
                        delete p2;
                    }
                }
                delete vec;
            }
            it->second = NULL;
        }
        delete p_railway;
        p_railway = NULL;
    }
    if(p_railwayaid != NULL) {
        delete p_railwayaid;
        p_railwayaid = NULL;
    }
    if(p_friendaid != NULL) {
        for(auto it = p_friendaid->begin(); it != p_friendaid->end(); it++) {
            auto set = it->second;
            delete set;
        }
        delete p_friendaid;
        p_friendaid = NULL;
    }
    if(p_astar != NULL) {
        delete p_astar;
        p_astar = NULL;
    }
    if(p_chunckGrid != NULL) {
        delete p_chunckGrid;
        p_chunckGrid = NULL;
    }
    if(p_chunckrailway != NULL) {
        for(auto it = p_chunckrailway->begin(); it != p_chunckrailway->end(); it++) {
            auto *vec = it->second;
            if(vec != NULL) {
                for(auto it2=vec->begin();it2!=vec->end();it2++) {
                    Railway* p2 = *it2;
                    if(p2 != NULL) {
                        delete p2;
                    }
                }
                delete vec;
            }
            it->second = NULL;
        }
        delete p_chunckrailway;
        p_chunckrailway = NULL;
    }
    if(p_chunckrailwayaid != NULL) {
        delete p_chunckrailwayaid;
        p_chunckrailwayaid = NULL;
    }
    if(p_chunckastar != NULL) {
        delete p_chunckastar;
        p_chunckastar = NULL;
    }
    if(!zoneconnect.empty()) {
        for(auto it=zoneconnect.begin();it!=zoneconnect.end();it++) {
            std::map<int, std::vector<Graph*>*>* mm = it->second;
            for(auto it3=mm->begin();it3!=mm->end();it3++) {
                std::vector<Graph*>* vec = it3->second;
                delete vec;
            }
            delete mm;
        }
        zoneconnect.clear();
    }
}

int MapSearch::testFun(int a, int b)
{
    printf("MapSearch::testFun a=%d, b=%d\n", a, b);
    return a + b;
}

int MapSearch::Init(unsigned int mapType, unsigned int mapSize, const char *mapFile, const char *railwayFile, unsigned int chunckSize, const char *chunckFile, const char *connectFile)
{
    printf("MapSearch::Init mapType=%d mapSize=%d mapFile=%s railwayFile=%s chunckSize=%d chunckFile=%s connectFile=%s\n", mapType, mapSize, mapFile, railwayFile, chunckSize, chunckFile, connectFile);
    if(mapType <= 0 || mapSize <= 0) {
        printf("MapSearch::Init error1: mapType=%d mapSize=%d mapFile=%s railwayFile=%s chunckSize=%d chunckFile=%s\n", mapType, mapSize, mapFile, railwayFile, chunckSize, chunckFile);
        return 0;
    }
    srand(time(NULL));

    m_mapType = mapType;
    m_mapSize = mapSize;

    if(p_mapGrid != NULL) {
        delete p_mapGrid;
        p_mapGrid = NULL;
    }
    p_mapGrid = new Array2D<Graph>(mapSize, mapSize);
    if(mapFile == NULL) {
        printf("MapSearch::Init error2: mapType=%d mapSize=%d mapFile=%s railwayFile=%s chunckSize=%d chunckFile=%s\n", mapType, mapSize, mapFile, railwayFile, chunckSize, chunckFile);
        return 0;
    } else {
        strncpy(m_mapFile, mapFile, sizeof(m_mapFile)-1);
        // printf("MapSearch::Init Map mapFile=%s\n", mapFile);
        lua_State *L = luaL_newstate();
        luaL_openlibs(L);
        luaL_dofile(L, mapFile);
        for	(unsigned int y=0; y<mapSize;y++) {
            for(unsigned int x=0; x<mapSize;x++) {
                (*p_mapGrid)(y, x).id = AStar::GetKey(x, y);
                (*p_mapGrid)(y, x).y = y;
                (*p_mapGrid)(y, x).x = x;
                (*p_mapGrid)(y, x).subzone = LuaGet(L, x+1, y+1);
                // printf("%d ", (*p_mapGrid)(y, x).subzone);
            }
            // printf("\n");
        }
        // printf("\n");
        lua_close(L);
    }
    if(p_railway != NULL) {
        for(auto it = p_railway->begin(); it != p_railway->end(); it++) {
            auto *vec = it->second;
            if(vec != NULL) {
                for(auto it2=vec->begin();it2!=vec->end();it2++) {
                    Railway* p2 = *it2;
                    if(p2 != NULL) {
                        delete p2;
                    }
                }
                delete vec;
            }
            it->second = NULL;
        }
        delete p_railway;
        p_railway = NULL;
    }
    p_railway = new std::map<int, std::vector<Railway*>*>();
    if(p_railwayaid != NULL) {
        delete p_railwayaid;
        p_railwayaid = NULL;
    }
    p_railwayaid = new std::map<int, unsigned long long>();
    if(railwayFile == NULL) {
        printf("MapSearch::Init error3: mapType=%d mapSize=%d mapFile=%s railwayFile=%s chunckSize=%d chunckFile=%s\n", mapType, mapSize, mapFile, railwayFile, chunckSize, chunckFile);
        return 0;
    } else {
        // printf("MapSearch::Init Map railwayFile=%s\n", railwayFile);
        lua_State *L = luaL_newstate();
        luaL_openlibs(L);
        luaL_dofile(L, railwayFile);
        LuaGet2(L, p_railway, p_railwayaid);
        lua_close(L);
    }
    if(p_friendaid != NULL) {
        for(auto it = p_friendaid->begin(); it != p_friendaid->end(); it++) {
            auto set = it->second;
            delete set;
        }
        delete p_friendaid;
        p_friendaid = NULL;
    }
    p_friendaid = new std::map<unsigned long long, std::set<unsigned long long>*>();
    if(p_astar != NULL) {
        delete p_astar;
        p_astar = NULL;
    }
    p_astar = new AStar(*p_mapGrid, *p_railway, *p_railwayaid, *p_friendaid, m_clear1, m_ptr1);
    m_chunckSize = chunckSize;
    if(p_chunckGrid != NULL) {
        delete p_chunckGrid;
        p_chunckGrid = NULL;
    }
    p_chunckGrid = new Array2D<Graph>(chunckSize, chunckSize);
    if(chunckFile == NULL) {
        printf("MapSearch::Init error4: mapType=%d mapSize=%d mapFile=%s railwayFile=%s chunckSize=%d chunckFile=%s\n", mapType, mapSize, mapFile, railwayFile, chunckSize, chunckFile);
        return 0;
    } else {
        lua_State *L = luaL_newstate();
        luaL_openlibs(L);
        luaL_dofile(L, chunckFile);
        for	(unsigned int y=0; y<chunckSize;y++) {
            for(unsigned int x=0; x<chunckSize;x++) {
                (*p_chunckGrid)(y, x).id = AStar::GetKey(x, y);
                (*p_chunckGrid)(y, x).y = y;
                (*p_chunckGrid)(y, x).x = x;
                (*p_chunckGrid)(y, x).subzone = LuaGet(L, x+1, y+1);
                // printf("%d ", (*p_chunckGrid)(y, x).subzone);
            }
            // printf("\n");
        }
        // printf("\n");
        lua_close(L);
    }
    if(p_chunckrailway != NULL) {
        for(auto it = p_chunckrailway->begin(); it != p_chunckrailway->end(); it++) {
            std::vector<Railway*> *vec = it->second;
            if(vec != NULL) {
                for(auto it2=vec->begin();it2!=vec->end();it2++) {
                    Railway* p2 = *it2;
                    if(p2 != NULL) {
                        delete p2;
                    }
                }
                delete vec;
            }
            it->second = NULL;
        }
        delete p_chunckrailway;
        p_chunckrailway = NULL;
    }
    p_chunckrailway = new std::map<int, std::vector<Railway*>*>();
    if(p_chunckrailwayaid != NULL) {
        delete p_chunckrailwayaid;
        p_chunckrailwayaid = NULL;
    }
    p_chunckrailwayaid = new std::map<int, unsigned long long>();
    if(p_railway != NULL) {
        for(auto it = p_railway->begin(); it != p_railway->end(); it++) {
            auto key = it->first;
            int newkey = AStar::KeyToChunckKey(key);
            auto vec = it->second;
            // printf("init p_chunckrailway===key=%d, newkey=%d ", key, newkey);
            std::vector<Railway*> *newvec = new std::vector<Railway*>();
            for(auto itt = vec->begin(); itt != vec->end(); itt++) {
                // printf("p_chunckrailway key=%d newkey=%d connectkey=%d connectnewkey=%d\n", key, newkey, (*itt)->id, AStar::KeyToChunckKey((*itt)->id));
                newvec->push_back(new Railway(AStar::KeyToChunckKey((*itt)->id), AStar::xToChunckX((*itt)->x), AStar::xToChunckX((*itt)->y)));
            }
            // printf("\n");
            p_chunckrailway->insert(std::make_pair(newkey, newvec));
        }
    }
    if(p_railwayaid != NULL) {
        for(auto it=p_railwayaid->begin();it !=p_railwayaid->end();it++) {
            auto key = it->first;
            auto newkey = AStar::KeyToChunckKey(key);
            p_chunckrailwayaid->insert(std::make_pair(newkey, it->second));
            // printf("init p_railwayaid===key=%d, newkey=%d aid=%lld\n", key, newkey, it->second);
        }
    }
    if(p_chunckastar != NULL) {
        delete p_chunckastar;
        p_chunckastar = NULL;
    }
    p_chunckastar = new AStar(*p_chunckGrid, *p_chunckrailway, *p_chunckrailwayaid, *p_friendaid, m_clear2, m_ptr2);

    if(connectFile == NULL) {
        printf("MapSearch::Init error5: mapType=%d mapSize=%d mapFile=%s railwayFile=%s chunckSize=%d chunckFile=%s connectFile=%s\n", mapType, mapSize, mapFile, railwayFile, chunckSize, chunckFile, connectFile);
        return 0;
    } else {
        if(!zoneconnect.empty()) {
            for(auto it=zoneconnect.begin();it!=zoneconnect.end();it++) {
                std::map<int, std::vector<Graph*>*>* mm = it->second;
                for(auto it3=mm->begin();it3!=mm->end();it3++) {
                    std::vector<Graph*>* vec = it3->second;
                    delete vec;
                }
                delete mm;
            }
            zoneconnect.clear();
        }
        lua_State *L = luaL_newstate();
        luaL_openlibs(L);
        luaL_dofile(L, connectFile);
        LuaGet3(L, zoneconnect, (*p_mapGrid));
        lua_close(L);
    }
    // printf("MapSearch::xxxxxxx() %d %d\n", m_ptr1.size(), m_ptr2.size());

    return 1;
}

Path* MapSearch::FindPath(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, unsigned long long aid, float speed, float railwayTime)
{
    printf("MapSearch::FindPath x1=%d, y1=%d, x2=%d, y2=%d aid=%lld speed=%f railwayTime=%f\n", x1, y1, x2, y2, aid, speed, railwayTime);
    if(!(x1 < m_mapSize && y1 < m_mapSize && x2 < m_mapSize && y2 < m_mapSize)) {
        printf("FindPath error1, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld\n", x1, y1, x2, y2, aid);
        return NULL;
    }

    #ifndef optimize
        /** 直接1197*1197寻路 **/
        std::list<Graph*>* ptr = p_astar->GetPath(x1, y1, x2, y2, aid, speed, railwayTime);
        #ifdef db1
            if (ptr != NULL && !ptr->empty()) {
                printf("MapSearch::FindPath finish0 ptr=>\n");
                for(auto it=ptr->begin();it!=ptr->end();it++) {
                    printf("(%d,%d)\t", (*it)->x, (*it)->y);
                }
                printf("\n");
            }
        #endif
        return ptr;
    #else
        /** 先133*133寻路, 再根据导航信息1197*1197寻路 **/
        Graph& startNode = (*p_mapGrid)(y1, x1);
        Graph& endNode = (*p_mapGrid)(y2, x2);
        if(startNode.subzone == AStar::WALL || endNode.subzone == AStar::WALL) {
            printf("FindPath error3, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld\n", x1, y1, x2, y2, aid);
            return NULL;
        }
        int cx1=(int)AStar::xToChunckX(x1), cy1=(int)AStar::xToChunckX(y1), cx2=(int)AStar::xToChunckX(x2), cy2=(int)AStar::xToChunckX(y2);
        bool isfind = false;
        if((*p_chunckGrid)(cy1, cx1).subzone == AStar::WALL) {
            int d = 0;
            while(!isfind && (++d)<=10) {
                int nx=cx1-d;
                for(int ny=cy1-d;ny<=cy1+d;ny++) {
                    if(ny >= 0 && ny < (int)m_chunckSize && nx!=cx1 && ny!=cy1 && (*p_chunckGrid)(ny, nx).subzone==endNode.subzone) {
                        cx1 = nx;
                        cy1 = ny;
                        isfind = true;
                        break;
                    }
                }
                nx=cx1+d;
                for(int ny=cy1-d;ny<=cy1+d;ny++) {
                    if(ny >= 0 && ny < (int)m_chunckSize && nx!=cx1 && ny!=cy1 && (*p_chunckGrid)(ny, nx).subzone==endNode.subzone) {
                        cx1 = nx;
                        cy1 = ny;
                        isfind = true;
                        break;
                    }
                }
                int ny=cy1-d;
                for(nx=cx1-(d-1);nx<=cx1+(d-1);nx++) {
                    if(ny >= 0 && ny < (int)m_chunckSize && nx!=cx1 && ny!=cy1 && (*p_chunckGrid)(ny, nx).subzone==endNode.subzone) {
                        cx1 = nx;
                        cy1 = ny;
                        isfind = true;
                        break;
                    }
                }
                ny=cy1+d;
                for(nx=cx1-(d-1);nx<=cx1+(d-1);nx++) {
                    if(ny >= 0 && ny < (int)m_chunckSize && nx!=cx1 && ny!=cy1 && (*p_chunckGrid)(ny, nx).subzone==endNode.subzone) {
                        cx1 = nx;
                        cy1 = ny;
                        isfind = true;
                        break;
                    }
                }
                if(isfind) break;
            }
        } else {
            isfind = true;
        }
        if(!isfind) {
            printf("FindPath error4, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld\n", x1, y1, x2, y2, aid);
            return NULL;
        }
        isfind = false;
        if((*p_chunckGrid)(cy2, cx2).subzone == AStar::WALL) {
            int d = 0;
            while(!isfind && (++d)<=10) {
                int nx=cx2-d;
                for(int ny=cy2-d;ny<=cy2+d;ny++) {
                    if(ny >= 0 && ny < (int)m_chunckSize && nx!=cx2 && ny!=cy2 && (*p_chunckGrid)(ny, nx).subzone==endNode.subzone) {
                        cx2 = nx;
                        cy2 = ny;
                        isfind = true;
                        break;
                    }
                }
                nx=cx2+d;
                for(int ny=cy2-d;ny<=cy2+d;ny++) {
                    if(ny >= 0 && ny < (int)m_chunckSize && nx!=cx2 && ny!=cy2 && (*p_chunckGrid)(ny, nx).subzone==endNode.subzone) {
                        cx2 = nx;
                        cy2 = ny;
                        isfind = true;
                        break;
                    }
                }
                int ny=cy2-d;
                for(nx=cx2-(d-1);nx<=cx2+(d-1);nx++) {
                    if(ny >= 0 && ny < (int)m_chunckSize && nx!=cx2 && ny!=cy2 && (*p_chunckGrid)(ny, nx).subzone==endNode.subzone) {
                        cx2 = nx;
                        cy2 = ny;
                        isfind = true;
                        break;
                    }
                }
                ny=cy2+d;
                for(nx=cx2-(d-1);nx<=cx2+(d-1);nx++) {
                    if(ny >= 0 && ny < (int)m_chunckSize && nx!=cx2 && ny!=cy2 && (*p_chunckGrid)(ny, nx).subzone==endNode.subzone) {
                        cx2 = nx;
                        cy2 = ny;
                        isfind = true;
                        break;
                    }
                }
            }
        } else {
            isfind = true;
        }
        if(!isfind) {
            printf("FindPath error5, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld\n", x1, y1, x2, y2, aid);
            return NULL;
        }
        if(!m_ptr2.empty()) {
            m_ptr2.clear();
        }
        std::list<Graph*>* ptr1 = p_chunckastar->GetPath(cx1, cy1, cx2, cy2, aid, speed, railwayTime/9.0, 8);
        if(ptr1 == NULL || ptr1->empty()) {
            printf("FindPath error6, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld\n", x1, y1, x2, y2, aid);
            return NULL;
        }
        #ifdef dbg
            printf("MapSearch::FindPath finish1 ptr1=>\n");
            for(auto it = ptr1->begin(); it != ptr1->end(); it++) {
                printf("(x=%d,y=%d,israilway=%d)\t", (*it)->x, (*it)->y, (*it)->israilway);
            }
            printf("\n");
        #endif
        if(!m_ptr1.empty()) {
            m_ptr1.clear();
        }
        auto ps1 = ptr1->begin();
        Graph* gph1 = *ps1;
        int subzone1 = gph1->subzone;
        auto ps2 = ps1;
        uint32_t tmpx1=0, tmpy1=0, tmpx2=0, tmpy2 = 0;
        std::list<Graph*>* ptr2 = NULL;
        Graph* lastcheck = NULL;
        if(subzone1==AStar::CHECK) {
            lastcheck = gph1;
        }
        while(ps2 != ptr1->end()) {
            ++ps2;
            if(ps2 == ptr1->end()) {
                break;
            }
            Graph* gph2 = *ps2;
            int subzone2 = gph2->subzone;
            if(subzone2==AStar::CHECK) {
                lastcheck = gph2;
            }
            if(((subzone2 != subzone1 || gph1->israilway || gph2->israilway) && subzone2!=AStar::CHECK) || gph2 == ptr1->back()) {
                if(gph1->israilway || gph2->israilway) {
                    if(ps1 == ptr1->begin()) {
                        tmpx1 = x1;
                        tmpy1 = y1;
                    } else {
                        auto it = m_ptr1.back();
                        tmpx1 = (*it).x;
                        tmpy1 = (*it).y;
                    }
                    if(gph1->israilway && gph2->israilway) {
                        if (gph2 == ptr1->back()) {
                            tmpx2 = AStar::midchunckxyToXY(gph2->x);
                            tmpy2 = AStar::midchunckxyToXY(gph2->y);
                            (*p_mapGrid)(tmpy1, tmpx1).israilway = 1;
                            addToPtr(tmpy1, tmpx1);
                            (*p_mapGrid)(tmpy2, tmpx2).israilway = 1;
                            addToPtr(tmpy2, tmpx2);
                            if(tmpx2!=x2 || tmpy2!=y2) {
                                ptr2 = p_astar->GetPath(tmpx2, tmpy2, x2, y2, aid, speed, railwayTime);
                                if(ptr2 == NULL || ptr2->empty()) {
                                    printf("FindPath error7, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx2=%d tmpy2=%d\n", x1, y1, x2, y2, aid, tmpx2, tmpy2);
                                    return NULL;
                                }
                                printPtr(ptr2);
                            }
                        } else {
                            if(isChunckRailwayConnect(gph1->id, gph2->id)) {
                                int tmpx3 = AStar::midchunckxyToXY(gph1->x);
                                int tmpy3 = AStar::midchunckxyToXY(gph1->y);
                                tmpx2 = AStar::midchunckxyToXY(gph2->x);
                                tmpy2 = AStar::midchunckxyToXY(gph2->y);
                                if(tmpx3!=(int)tmpx1 || tmpy3!=(int)tmpy1) {
                                    ptr2 = p_astar->GetPath(tmpx1, tmpy1, tmpx3, tmpy3, aid, speed, railwayTime);
                                    if(ptr2 == NULL || ptr2->empty()) {
                                        printf("FindPath error8, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx2=%d tmpy2=%d\n", x1, y1, x2, y2, aid, tmpx2, tmpy2);
                                        return NULL;
                                    }
                                    printPtr(ptr2);
                                }
                                (*p_mapGrid)(tmpy3, tmpx3).israilway = 1;
                                addToPtr(tmpy3, tmpx3);
                                (*p_mapGrid)(tmpy2, tmpx2).israilway = 1;
                                addToPtr(tmpy2, tmpx2);
                                printPtr(ptr2);
                            } else {
                                tmpx2 = AStar::midchunckxyToXY(gph2->x);
                                tmpy2 = AStar::midchunckxyToXY(gph2->y);
                                ptr2 = p_astar->GetPath(tmpx1, tmpy1, tmpx2, tmpy2, aid, speed, railwayTime);
                                if(ptr2 == NULL || ptr2->empty()) {
                                    printf("FindPath error9, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx2=%d tmpy2=%d\n", x1, y1, x2, y2, aid, tmpx2, tmpy2);
                                    return NULL;
                                }
                                printPtr(ptr2);
                            }
                        }
                    } else if (gph1->israilway) {
                        subzone1 = (*p_mapGrid)(tmpy1, tmpx1).subzone;
                        if(subzone1 == subzone2 && gph2 != ptr1->back()) {
                            continue;
                        }
                        if (gph2 == ptr1->back()) {
                            Graph* gph3 = findConnect(subzone1, subzone2, lastcheck);
                            Graph* gph4 = findConnect(subzone2, subzone1, lastcheck);
                            if (gph3 && gph4) {
                                ptr2 = p_astar->GetPath(tmpx1, tmpy1, gph3->x, gph3->y, aid, speed, railwayTime);
                                if(ptr2 == NULL || ptr2->empty()) {
                                    printf("FindPath error10, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx1=%d tmpy1=%d tmpx2=%d tmpy2=%d\n", x1, y1, x2, y2, aid, tmpx1, tmpy1, tmpx2, tmpy2);
                                    return NULL;
                                }
                                printPtr(ptr2);
                                tmpx1 = gph4->x;
                                tmpy1 = gph4->y;
                            }
                            tmpx2 = x2;
                            tmpy2 = y2;
                            ptr2 = p_astar->GetPath(tmpx1, tmpy1, tmpx2, tmpy2, aid, speed, railwayTime);
                            if(ptr2 == NULL || ptr2->empty()) {
                                printf("FindPath error11, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx1=%d tmpy1=%d tmpx2=%d tmpy2=%d\n", x1, y1, x2, y2, aid, tmpx1, tmpy1, tmpx2, tmpy2);
                                return NULL;
                            }
                            printPtr(ptr2);
                        } else {
                            Graph* gph3 = findConnect(subzone1, subzone2, lastcheck);
                            Graph* gph4 = findConnect(subzone2, subzone1, lastcheck);
                            if(gph3 == NULL || gph4 == NULL) {
                                printf("FindPath error12, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx1=%d tmpy1=%d subzone1=%d subzone2=%d\n", x1, y1, x2, y2, aid, tmpx1, tmpy1, subzone1, subzone2);
                                return NULL;
                            }
                            tmpx2 = gph3->x;
                            tmpy2 = gph3->y;
                            ptr2 = p_astar->GetPath(tmpx1, tmpy1, tmpx2, tmpy2, aid, speed, railwayTime);
                            if(ptr2 == NULL || ptr2->empty()) {
                                printf("FindPath error13, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx1=%d tmpy1=%d tmpx2=%d tmpy2=%d\n", x1, y1, x2, y2, aid, tmpx1, tmpy1, tmpx2, tmpy2);
                                return NULL;
                            }
                            addToPtr(gph4->y, gph4->x);
                            printPtr(ptr2);
                        }
                    } else {
                        tmpx2 = AStar::midchunckxyToXY(gph2->x);
                        tmpy2 = AStar::midchunckxyToXY(gph2->y);
                        ptr2 = p_astar->GetPath(tmpx1, tmpy1, tmpx2, tmpy2, aid, speed, railwayTime);
                        if(ptr2 == NULL || ptr2->empty()) {
                            printf("FindPath error14, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx2=%d tmpy2=%d\n", x1, y1, x2, y2, aid, tmpx2, tmpy2);
                            return NULL;
                        }
                        (*p_mapGrid)(tmpy2, tmpx2).israilway = 1;
                        printPtr(ptr2);
                    }
                } else {
                    if(ps1 == ptr1->begin()) {
                        tmpx1 = x1;
                        tmpy1 = y1;
                    } else {
                        auto it = m_ptr1.back();
                        tmpx1 = (*it).x;
                        tmpy1 = (*it).y;
                    }
                    subzone1 = (*p_mapGrid)(tmpy1, tmpx1).subzone;
                    if(subzone1 == subzone2 && gph2 != ptr1->back()) {
                        continue;
                    }
                    if (gph2 == ptr1->back()) {
                        Graph* gph3 = findConnect(subzone1, subzone2, lastcheck);
                        Graph* gph4 = findConnect(subzone2, subzone1, lastcheck);
                        if (gph3 && gph4) {
                            ptr2 = p_astar->GetPath(tmpx1, tmpy1, gph3->x, gph3->y, aid, speed, railwayTime);
                            if(ptr2 == NULL || ptr2->empty()) {
                                printf("FindPath error15, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx1=%d tmpy1=%d tmpx2=%d tmpy2=%d\n", x1, y1, x2, y2, aid, tmpx1, tmpy1, tmpx2, tmpy2);
                                return NULL;
                            }
                            printPtr(ptr2);
                            tmpx1 = gph4->x;
                            tmpy1 = gph4->y;
                        }
                        tmpx2 = x2;
                        tmpy2 = y2;
                        ptr2 = p_astar->GetPath(tmpx1, tmpy1, tmpx2, tmpy2, aid, speed, railwayTime);
                        if(ptr2 == NULL || ptr2->empty()) {
                            printf("FindPath error16, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx1=%d tmpy1=%d tmpx2=%d tmpy2=%d\n", x1, y1, x2, y2, aid, tmpx1, tmpy1, tmpx2, tmpy2);
                            return NULL;
                        }
                        printPtr(ptr2);
                    } else {
                        if(subzone1==AStar::CHECK) {
                            Graph* gph3 = findConnect(subzone1, subzone2, lastcheck);
                            if(gph3 == NULL) {
                                printf("FindPath error17, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx1=%d tmpy1=%d subzone1=%d subzone2=%d\n", x1, y1, x2, y2, aid, tmpx1, tmpy1, subzone1, subzone2);
                                return NULL;
                            }
                            tmpx2 = gph3->x;
                            tmpy2 = gph3->y;
                            ptr2 = p_astar->GetPath(tmpx1, tmpy1, tmpx2, tmpy2, aid, speed, railwayTime);
                            if(ptr2 == NULL || ptr2->empty()) {
                                printf("FindPath error18, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx1=%d tmpy1=%d tmpx2=%d tmpy2=%d\n", x1, y1, x2, y2, aid, tmpx1, tmpy1, tmpx2, tmpy2);
                                return NULL;
                            }
                            printPtr(ptr2);
                        } else {
                            Graph* gph3 = findConnect(subzone1, subzone2, lastcheck);
                            Graph* gph4 = findConnect(subzone2, subzone1, lastcheck);
                            if(gph3 == NULL || gph4 == NULL) {
                                printf("FindPath error19, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx1=%d tmpy1=%d subzone1=%d subzone2=%d\n", x1, y1, x2, y2, aid, tmpx1, tmpy1, subzone1, subzone2);
                                return NULL;
                            }
                            tmpx2 = gph3->x;
                            tmpy2 = gph3->y;
                            ptr2 = p_astar->GetPath(tmpx1, tmpy1, tmpx2, tmpy2, aid, speed, railwayTime);
                            if(ptr2 == NULL || ptr2->empty()) {
                                printf("FindPath error20, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld tmpx1=%d tmpy1=%d tmpx2=%d tmpy2=%d\n", x1, y1, x2, y2, aid, tmpx1, tmpy1, tmpx2, tmpy2);
                                return NULL;
                            }
                            addToPtr(gph4->y, gph4->x);
                            printPtr(ptr2);
                        }
                    }
                }
                //next
                if(gph2 == ptr1->back()) {
                    break;
                } else {
                    ps1 = ps2;
                    gph1 = *ps1;
                    subzone1 = subzone2;
                }
            }
        }
        #ifdef dbg
            if (ptr2 != NULL && !ptr2->empty()) {
                printf("MapSearch::FindPath finish2 ptr2=>\n");
                for(auto it=ptr2->begin();it!=ptr2->end();it++) {
                    printf("(x=%d,y=%d,israilway=%d)\t", (*it)->x, 1196-(*it)->y, (*it)->israilway);
                }
                printf("\n");
            }
        #endif
        if(m_ptr1.empty()) {
            printf("FindPath error21, mapSearch.cpp x1=%d y1=%d x2=%d y2=%d aid=%lld\n", x1, y1, x2, y2, aid);
            return NULL;
        }
        if (aid > 0) {
            for(auto pit=m_ptr1.begin();pit!=m_ptr1.end();pit++) {
                (*pit)->israilway = 0;
            }
            for(auto pit=m_ptr1.begin();pit!=m_ptr1.end();pit++) {
                Graph* gph = *pit;
                auto pit2 = pit;
                ++pit2;
                if(pit2 == m_ptr1.end()) {
                    break;
                }
                Graph* gph2 = *pit2;
                if(p_astar->IsUsableRailway(gph->id, aid) && p_astar->IsUsableRailway(gph2->id, aid) && isRailwayConnect(gph->id, gph2->id)) {
                    if (gph->israilway == 0) {
                        gph->israilway = 1;
                        m_clear1.push_back(gph);
                    }
                }
            }
            printPtr(ptr2);
        }
        Path *pth = (Path*) malloc(sizeof(Path));
        pth->count = m_ptr1.size();
        pth->ps = NULL;
        pth->ps = (Pos*) calloc(pth->count, sizeof(Pos));
        Pos *tmpps = pth->ps;
        for(auto pit=m_ptr1.begin();pit!=m_ptr1.end();pit++) {
            Graph* gph = *pit;
            tmpps->x = gph->x;
            tmpps->y = gph->y;
            tmpps->railway = gph->israilway;
            ++tmpps;
        }
        return pth;
    #endif
}

inline Graph* MapSearch::findConnect(int subzone1, int subzone2, Graph* gph1) {
    if (gph1) {
        if(subzone1==AStar::CHECK) {
            auto it = zoneconnect.find(subzone2);
            if(it != zoneconnect.end()) {
                std::map<int, std::vector<Graph*>*>* mm = it->second;
                for(auto it2=mm->begin();it2!=mm->end();it2++) {
                    std::vector<Graph*>* vec3 = it2->second;
                    for(auto it3 = vec3->begin(); it3 != vec3->end(); it3++) {
                        Graph* tmp = (*it3);
                        if (abs((int)AStar::xToChunckX(tmp->x)-gph1->x)<=2 && abs((int)AStar::xToChunckX(tmp->y)-gph1->y)<=2) {
                            return (*it3);
                        }
                    }
                }
            }
        } else {
            auto it = zoneconnect.find(subzone1);
            if(it != zoneconnect.end()) {
                std::map<int, std::vector<Graph*>*>* mm = it->second;
                auto it2 = mm->find(subzone2);
                if(it2 != mm->end()) {
                    std::vector<Graph*>* vec3 = it2->second;
                    for(auto it3 = vec3->begin(); it3 != vec3->end(); it3++) {
                        Graph* tmp = (*it3);
                        if (abs((int)AStar::xToChunckX(tmp->x)-gph1->x)<=2 && abs((int)AStar::xToChunckX(tmp->y)-gph1->y)<=2) {
                            return (*it3);
                        }
                    }
                }
            }
        }
    }
    return NULL;
}

inline void MapSearch::addToPtr(uint32_t tmpy1, uint32_t tmpx1) {
    Graph* tmpNode1 = &(*p_mapGrid)(tmpy1, tmpx1);
    bool isfind=false;
    for(auto tt =m_ptr1.begin();tt!=m_ptr1.end();tt++){
        if((*tt)==tmpNode1) {
            isfind=true;
            break;
        }
    }
    if(!isfind) {
        m_ptr1.push_back(tmpNode1);
        m_clear1.push_back(tmpNode1);
    }
}

void MapSearch::printPtr(std::list<Graph*>* ptr2) {
    if (ptr2 != NULL && !ptr2->empty()) {
        printf("MapSearch::printPtr== ptr2=>\n");
        for(auto it=ptr2->begin();it!=ptr2->end();it++) {
            printf("(x=%d,y=%d,israilway=%d)\t", (*it)->x, 1196-(*it)->y, (*it)->israilway);
        }
        printf("\n");
    }
}

int MapSearch::SetRailwayAid(int x, int y, unsigned long long aid) {
    if(x < 0 || x >= (int)p_mapGrid->row() || y < 0 || y >= (int)p_mapGrid->row()) {
        return 0;
    }
    int key = AStar::GetKey(x, y);
    auto it = p_railwayaid->find(key);
    if(it == p_railwayaid->end()) {
        printf("SetRailwayAid error1, mapSearch.cpp x=%d y=%d aid=%lld\n", x, y, aid);
        return 0;
    }
    it->second = aid;

    int key2 = p_chunckastar->xyToChunckKey(x, y);
    auto it2 = p_chunckrailwayaid->find(key2);
    if(it2 == p_chunckrailwayaid->end()) {
        printf("SetRailwayAid error2, mapSearch.cpp x=%d y=%d aid=%lld\n", x, y, aid);
        return 0;
    }
    it2->second = aid;

    return 1;
}

int MapSearch::SetFriendAid(unsigned long long aid1, unsigned long long aid2, bool isadd) {
    if (aid1 > 0 && aid2 > 0) {
        if (isadd) {
            auto it1 = p_friendaid->find(aid1);
            if(it1 == p_friendaid->end()) {
                auto set = new std::set<unsigned long long>();
                set->insert(aid2);
                p_friendaid->insert(std::make_pair(aid1, set));
            } else {
                auto set = it1->second;
                set->insert(aid2);
            }
            auto it2 = p_friendaid->find(aid2);
            if(it2 == p_friendaid->end()) {
                auto set = new std::set<unsigned long long>();
                set->insert(aid1);
                p_friendaid->insert(std::make_pair(aid2, set));
            } else {
                auto set = it2->second;
                set->insert(aid1);
            }
            return 1;
        } else {
            auto it1 = p_friendaid->find(aid1);
            if(it1 != p_friendaid->end()) {
                auto set = it1->second;
                auto itt = set->find(aid2);
                if(itt != set->end()) {
                    set->erase(itt);
                    if(set->empty()) {
                        p_friendaid->erase(it1);
                    }
                }
            } 
            auto it2 = p_friendaid->find(aid2);
            if(it2 != p_friendaid->end()) {
                auto set = it1->second;
                auto itt = set->find(aid1);
                if(itt != set->end()) {
                    set->erase(itt);
                    if(set->empty()) {
                        p_friendaid->erase(it2);
                    }
                }
            }
            return 1;
        }
    }
    return 0;
}

inline bool MapSearch::isChunckRailwayConnect(int id1, int id2) {
    auto it = p_chunckrailway->find(id1);
    if(it!=p_chunckrailway->end()) {
        auto it2 = it->second;
        for(auto it3 = it2->begin();it3!=it2->end();it3++) {
            if((*it3)->id ==id2) {
                return true;
            }
        }
    }
    return false;
}

inline bool MapSearch::isRailwayConnect(int id1, int id2) {
    auto it = p_railway->find(id1);
    if(it!=p_railway->end()) {
        auto it2 = it->second;
        for(auto it3 = it2->begin();it3!=it2->end();it3++) {
            if((*it3)->id ==id2) {
                return true;
            }
        }
    }
    return false;
}