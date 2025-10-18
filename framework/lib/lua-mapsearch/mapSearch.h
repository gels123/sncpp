//
//  mapSearch.cpp
//
//  Created by GeLiusheng on 2021/12/28.
//  Copyright © 2021年 Liusheng Ge. All rights reserved.
//

#ifndef mapSearch_h
#define mapSearch_h

#include <stdio.h>
#include <map>
#include <vector>
#include <set>
#include <list>
#include "astar.h"
#include "lua-mapSearch.h"

using namespace alg;

class MapSearch
{
public:
    int testFun(int a, int b);

public:
    MapSearch();
    ~MapSearch();

    int Init(unsigned int mapType, unsigned int mapSize, const char *mapFile, const char *railwayFile, unsigned int chunckSize, const char *chunckFile, const char *connectFile);
    Path* FindPath(unsigned int x1, unsigned int y1, unsigned int x2, unsigned int y2, unsigned long long aid=0, float speed = 2.0, float railwayTime = 10.0);
    int SetRailwayAid(int x, int y, unsigned long long aid);
    int SetFriendAid(unsigned long long aid1, unsigned long long aid2, bool isadd);
    Graph* findConnect(int subzone1, int subzone2, Graph* gph1);
    void addToPtr(uint32_t tmpy1, uint32_t tmpx1);
    void printPtr(std::list<Graph*>* ptr2);
    bool isChunckRailwayConnect(int id1, int id2);
    bool isRailwayConnect(int id1, int id2);

public:
    unsigned int m_mapType;
    unsigned int m_mapSize;
    char m_mapFile[256];
    Array2D<Graph> *p_mapGrid;
    std::map<int, std::vector<Railway*> *> *p_railway;
    std::map<int, unsigned long long> *p_railwayaid;
    std::map<unsigned long long, std::set<unsigned long long>*> *p_friendaid;
    AStar *p_astar;
    unsigned int m_chunckSize;
    Array2D<Graph> *p_chunckGrid;
    std::map<int, std::vector<Railway*> *> *p_chunckrailway;
    std::map<int, unsigned long long> *p_chunckrailwayaid;
    AStar *p_chunckastar;
    std::vector<Graph*> m_clear1;
    std::vector<Graph*> m_clear2;
    std::list<Graph*> m_ptr1;
    std::list<Graph*> m_ptr2;
    std::map<int, std::map<int, std::vector<Graph*>*>*> zoneconnect;
};

#endif /* mapSearch_h */
