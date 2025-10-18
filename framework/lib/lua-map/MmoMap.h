//
// Created by gels on 2023/1/13.
//

#ifndef SN_GAME_SERVER_MMOMAP_H
#define SN_GAME_SERVER_MMOMAP_H

extern int mmoArray[2];

typedef struct mmoStInfo {
    int x;
    int y;
    char str[64];
} mmoStInfo;

extern mmoStInfo tmpInfo;

class MmoMap {
public:
    MmoMap();
    MmoMap(int sizeX, int sizeY);
    virtual ~MmoMap();
    /**
     * 返回多个值
     * local map = MmoMap:new(5, 6); local x, y = map:GetSize()
     */
    void GetSize(int *x = 0, int *y = 0);
    /**
     * 返回单个个值
     * local map = MmoMap:new(5, 6); local x = map:GetSizeX()
     */
    int GetSizeX();
    int GetSizeY();
    /**
     * 返回一个结构
     * local map = MmoMap:new(5, 6); local info = map:GetInfo()
     */
    mmoStInfo *GetInfo();
    /**
     * 静态方法
     */
     static int GetVersion();
private:
    int nSizeX;
    int nSizeY;
};


#endif //SN_GAME_SERVER_MMOMAP_H
