//
// Created by gels on 2023/1/13.
//

#include "MmoMap.h"
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

int mmoArray[2] = {100, 200};

mmoStInfo tmpInfo = {0, 0, {0}};

MmoMap::MmoMap() {
    nSizeX = 0;
    nSizeY = 0;
}

MmoMap::MmoMap(int sizeX, int sizeY) {
    nSizeX = sizeX;
    nSizeY = sizeY;
}

MmoMap::~MmoMap() {

}

void MmoMap::GetSize(int *x, int *y) {
    *x = nSizeX;
    *y = nSizeY;
}

int MmoMap::GetSizeX() {
    return nSizeX;
}

int MmoMap::GetSizeY() {
    return nSizeY;
}

mmoStInfo *MmoMap::GetInfo() {
    tmpInfo.x = nSizeX;
    tmpInfo.y = nSizeY;
    memset(tmpInfo.str, '\0', sizeof(tmpInfo.str));
    char str[] = "1234567891011";
    printf("GetInfo===info.strsize=%d strsize=%d \n", sizeof(tmpInfo.str), sizeof(str));
    memcpy(tmpInfo.str, str, sizeof(str));
    return &tmpInfo;
}

int MmoMap::GetVersion() {
    return 222;
}