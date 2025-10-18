//
// Created by iwins on 2023/2/1.
//

#include "NpcInfo.h"
#include <stdio.h>

NpcInfo::NpcInfo() {
    npcId = 0;
    hunger = 0;
}

NpcInfo::~NpcInfo() {
    printf("NpcInfo::~NpcInfo\n");
}

bool NpcInfo::OnTick() {
    return true;
}
