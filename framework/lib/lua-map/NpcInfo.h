//
// npc角色信息
//

#ifndef WHALEMETA_GAME_SERVER_NPCINFO_H
#define WHALEMETA_GAME_SERVER_NPCINFO_H

//npc角色基础信息
class NpcInfo {
public:
    NpcInfo();
    virtual ~NpcInfo();
    bool OnTick();

public:
    int npcId;          //ID
    int hunger;         //饥饿感
    int state;          //状态
    int subState;       //子状态
    int stateStartTime; //状态开始时间
    int stateEndTime;   //状态结束时间
};


#endif //WHALEMETA_GAME_SERVER_NPCINFO_H
