#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

#include "lua.h"
#include "lauxlib.h"


// function for line generation
/* 参考
https://www.geeksforgeeks.org/bresenhams-line-generation-algorithm/
*/
static int lua_f_bresenham(lua_State *L) 
{ 
    int data[4]={0};
    int argc = lua_gettop(L);
    if( 4 != argc )
    {
        lua_pushnil(L);
        return 1;
    }
    short i = 0;
    for(;i<argc;i++)
    {
        data[i] = lua_tointeger(L, i+1);
    }
    // x1 必须小于  x2
    int x1 = data[0];
    int y1 = data[1];

    int x2 = data[2];
    int y2 = data[3];
    // printf("x1=%d,y1=%d,x2=%d,y2=%d\n",x1,y1,x2,y2);
    int m_new = 2 * (y2 - y1); 
    int slope_error_new = m_new - (x2 - x1); 
    
    // 构造一个新的table
    lua_newtable(L);
    int n = 0;
    int x = x1, y = y1;
    for (; x <= x2; x++) 
    { 
        n++;
        int one = x * 10000 + y; //将2维数据转成1维,最大支持Y为4位数 
        lua_pushinteger(L,one);
        lua_rawseti(L, -2, n); 

        // Add slope to increment angle formed 
        slope_error_new += m_new; 

        // Slope error reached limit, time to 
        // increment y and update slope error. 
        if (slope_error_new >= 0) 
        { 
            y++; 
            slope_error_new  -= 2 * (x2 - x1); 
        }
    }
    return 1;
}

//Function for finding absolute value 
int abs (int n) 
{ 
    return ( (n>0) ? n : ( n * (-1))); 
}
/*
https://www.geeksforgeeks.org/dda-line-generation-algorithm-computer-graphics/
*/
static int lua_f_dda(lua_State *L) 
{ 
    int data[4]={0};
    int argc = lua_gettop(L);
    if( 4 != argc )
    {
        lua_pushnil(L);
        return 1;
    }
    short index = 0;
    for(;index<argc;index++)
    {
        data[index] = lua_tointeger(L, index+1);
    }
    // x1 必须小于  x2
    int X0 = data[0];
    int Y0 = data[1];

    int X1 = data[2];
    int Y1 = data[3];
    // printf("x1=%d,y1=%d,x2=%d,y2=%d\n",X0,Y0,X1,Y1);
    
    // calculate dx & dy 
    int dx = X1 - X0; 
    int dy = Y1 - Y0; 
  
    // calculate steps required for generating pixels 
    int steps = abs(dx) > abs(dy) ? abs(dx) : abs(dy); 
  
    // calculate increment in x & y for each steps 
    float Xinc = dx / (float) steps; 
    float Yinc = dy / (float) steps; 
  
    // Put pixel for each step 
    float X = X0; 
    float Y = Y0;
    // 构造一个新的table
    lua_newtable(L);
    int n = 0;
    int i = 0;
    for (; i <= steps; i++) 
    { 
        n++;
        int one = (int)X * 10000 + (int)Y; //将2维数据转成1维,最大支持Y为4位数 
        lua_pushinteger(L,one);
        lua_rawseti(L, -2, n);
        X += Xinc;           // increment in x at each step 
        Y += Yinc;           // increment in y at each step 
    }
    return 1;
}

// http://eugen.dedu.free.fr/projects/bresenham/
static int lua_improved_bresenham (lua_State *L) 
{ 
    int data[4]={0};
    int argc = lua_gettop(L);
    if( 4 != argc )
    {
        lua_pushnil(L);
        return 1;
    }
    short index = 0;
    for(;index<argc;index++)
    {
        data[index] = lua_tointeger(L, index+1);
    }
    // x1 必须小于  x2
    int x1 = data[0];
    int y1 = data[1];

    int x2 = data[2];
    int y2 = data[3];
    // printf("x1=%d,y1=%d,x2=%d,y2=%d\n",x1,y1,x2,y2);

    int i;               // loop counter 
    int ystep, xstep;    // the step on y and x axis 
    int error;           // the error accumulated during the increment 
    int errorprev;       // *vision the previous value of the error variable 
    int y = y1, x = x1;  // the line points 
    int ddy, ddx;        // compulsory variables: the double values of dy and dx 
    int dx = x2 - x1; 
    int dy = y2 - y1; 
    
    // 构造一个新的table
    lua_newtable(L);
    int n = 0;
    
    n++;
    //first point
    int one = x1 * 10000 + y1; //将2维数据转成1维,最大支持Y为4位数 
    lua_pushinteger(L,one);
    lua_rawseti(L, -2, n); 

    // NB the last point can't be here, because of its previous point (which has to be verified) 
    if (dy < 0){ 
        ystep = -1; 
        dy = -dy; 
    }else 
        ystep = 1; 
    if (dx < 0){ 
        xstep = -1; 
        dx = -dx; 
    }else 
        xstep = 1; 
    
    ddy = 2 * dy;  // work with double values for full precision 
    ddx = 2 * dx; 
    if (ddx >= ddy){  // first octant (0 <= slope <= 1) 
        // compulsory initialization (even for errorprev, needed when dx==dy) 
        errorprev = error = dx;  // start in the middle of the square 
        for (i=0 ; i < dx ; i++){  // do not use the first point (already done) 
          x += xstep; 
          error += ddy; 
          if (error > ddx){  // increment y if AFTER the middle ( > ) 
            y += ystep; 
            error -= ddx; 
            // three cases (octant == right->right-top for directions below): 
            if (error + errorprev < ddx)  // bottom square also 
            {
                n++;
                one = x * 10000 + (y-ystep); //将2维数据转成1维,最大支持Y为4位数 
                lua_pushinteger(L,one);
                lua_rawseti(L, -2, n);
            } 
            else if (error + errorprev > ddx)  // left square also 
            {
                n++;
                one = (x-xstep) * 10000 + y; //将2维数据转成1维,最大支持Y为4位数 
                lua_pushinteger(L,one);
                lua_rawseti(L, -2, n);
            } 
            else{  // corner: bottom and left squares also 
                n++;
                one = x * 10000 + (y-ystep); //将2维数据转成1维,最大支持Y为4位数 
                lua_pushinteger(L,one);
                lua_rawseti(L, -2, n);

                n++;
                one = (x-xstep) * 10000 + y; //将2维数据转成1维,最大支持Y为4位数 
                lua_pushinteger(L,one);
                lua_rawseti(L, -2, n);
            } 
          } 
            n++;
            one = x * 10000 + y; //将2维数据转成1维,最大支持Y为4位数 
            lua_pushinteger(L,one);
            lua_rawseti(L, -2, n); 
            errorprev = error; 
        } 
    }else{  // the same as above 
        errorprev = error = dy; 
        for (i=0 ; i < dy ; i++){ 
          y += ystep; 
          error += ddx; 
          if (error > ddy){ 
            x += xstep; 
            error -= ddy; 
            if (error + errorprev < ddy) 
            {
                n++;
                one = (x-xstep) * 10000 + y; //将2维数据转成1维,最大支持Y为4位数 
                lua_pushinteger(L,one);
                lua_rawseti(L, -2, n);
            }
            else if (error + errorprev > ddy) 
            {
                n++;
                one = x * 10000 + (y-ystep); //将2维数据转成1维,最大支持Y为4位数 
                lua_pushinteger(L,one);
                lua_rawseti(L, -2, n);
            } 
            else{
                n++;
                one = (x-xstep) * 10000 + y; //将2维数据转成1维,最大支持Y为4位数 
                lua_pushinteger(L,one);
                lua_rawseti(L, -2, n);

                n++;
                one = x * 10000 + (y-ystep); //将2维数据转成1维,最大支持Y为4位数 
                lua_pushinteger(L,one);
                lua_rawseti(L, -2, n);
            } 
          }
            n++;
            one = x * 10000 + y; //将2维数据转成1维,最大支持Y为4位数 
            lua_pushinteger(L,one);
            lua_rawseti(L, -2, n);
            errorprev = error; 
        }
    } 
    // assert ((y == y2) && (x == x2));  // the last point (y2,x2) has to be the same with the last point of the algorithm 
    return 1;
}

LUALIB_API int 
luaopen_cutils( lua_State *L )
{
    luaL_checkversion(L);

    luaL_Reg l[] = {
        {"bresenham",lua_f_bresenham},
        {"supercover",lua_improved_bresenham},
        {"dda",lua_f_dda},
        {NULL, NULL}
    };
    luaL_newlib(L,l);
    return 1;
}
