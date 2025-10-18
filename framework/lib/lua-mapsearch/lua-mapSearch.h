/*
 *  author: gels
 *  date: 2021-12-28 20:00
 */

#ifndef lua_mapSearch
#define lua_mapSearch

#include <stdio.h>
#include <stdlib.h>

typedef struct Pos_
{
    int x, y, railway;
} Pos;

typedef struct Path_
{   
    Pos *ps;
    int count;
} Path;

inline void releasePath(Path *ptr)
{
    if(ptr != NULL) {
        if(ptr->ps != NULL) {
            free(ptr->ps);
            ptr->ps = NULL;
        }
        free(ptr);
        ptr = NULL;
    }
}

#endif /* lua_mapSearch */
