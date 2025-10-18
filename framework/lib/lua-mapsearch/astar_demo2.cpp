#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "astar.h"
#include "mapSearch.h"

int main(void)
{
    MapSearch *ms = new MapSearch();
    // ms->Init(1, 8, "/home/share/lnx_server4/server/server/map/search/bitmap/map4.lua", "/home/share/lnx_server4/server/server/map/search/bitmap/railway4.lua");
    ms->Init(1, 1197, "/home/share/lnx_server4/server/server/map/search/bitmap/posmap.lua", "/home/share/lnx_server4/server/server/map/search/bitmap/EditMapRailwayServer.lua", 133, "/home/share/lnx_server4/server/server/map/search/bitmap/chunckmap.lua", "/home/share/lnx_server4/server/server/map/search/bitmap/zoneconnect.lua");

    printf("=================\n");
    // for(int i=0;i<100;i++) {
        // int x1 = 255, y1 = 1021, x2 =600, y2 =600; 
        //(177,958)	(181,934)	(181,933)	(181,932)	(210,655)	(210,649)
        // int x1 = 177, y1 = 958, x2 =210, y2 =655; //有点问题
        ms->SetRailwayAid(31, 1196-1165, 123);
        ms->SetRailwayAid(40, 1196-1111, 123);
        ms->SetRailwayAid(103, 1196-1147, 123);

        ms->SetRailwayAid(157, 1196-1111, 123);
        ms->SetRailwayAid(229, 1196-1093, 123);

        printf("=====%d======\n", ms->p_astar->IsUsableRailway(30003, 123));
        
        int x1 = 28, y1 = 1168, x2 =230, y2 =1093;//1196-178
        Path* path = ms->FindPath(x1, 1196-y1, x2, 1196-y2, 123);  //（2, 2）（4, 3）

        // Path* path = ms->FindPath(24, 1092, 83, 134, 0);  //（2, 2）（4, 3）

        delete ms;
        if(path) {
            releasePath(path);
        }

        // int x1 = 1, y1 = 1, x2 =10, y2 =10;
        // ms->FindPath(x1, y1, x2, y2);

        // ms->FindPath(0, 0, 10, 10);
    // }
// (464,804)	(461,805)	(460,805)	(376,805)	(375,805)  (371,805)	(370,805)	(311,834)	(310,835)	(308,836)	(307,837)	(177,956)	
// (597,637)	(516,748)	(516,749)	(515,751)	(514,752)	(509,756)	(371,772)	(311,828)	(310,829)	(308,831)	(307,832)   (177,956)	

	return 0;
}
