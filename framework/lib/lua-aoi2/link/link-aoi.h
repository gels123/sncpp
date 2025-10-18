#ifndef LINK_AOI_H
#define LINK_AOI_H

#include "hash_witness.h"

#define AOI_ENTITY 		1
#define AOI_LOW_BOUND 	2
#define AOI_HIGH_BOUND 	4

#define UNLIMITED -1000

#define IN -1
#define OUT 1

#define LINKAOI_HAVE_RESTORE_WITNESS
#define LINKAOI_HAVE_RESTORE_VISIBLE

#ifdef _WIN32
#define inline __inline
#endif

struct aoi_entity;
struct aoi_trigger;
struct aoi_context;
struct linknode;
struct position;

typedef void(*foreach_entity_func)(int objid, int x, int z, void* ud);
typedef void(*foreach_trigger_func)(int objid, int x, int z, int range, void* ud);
typedef void(*callback_func)(int self, int other, void* ud);

typedef int(*cmp_func)(struct position*, struct position*);
typedef void(*shuffle_func)(struct aoi_context*, struct linknode*, int);

typedef struct position {
    int x;
    int z;
} position_t;

// 单个entity/trigger对象
typedef struct aoi_object {
    int objid;                      // 对象id
    struct aoi_entity* entity;      // 被观察者对象
    struct aoi_trigger* trigger;    // 观察者对象

    struct aoi_object* next;        // 进入/离开列表节点
    struct aoi_object* prev;        // 进入/离开列表节点

    int inout;
} aoi_object_t;

// 双向链表节点
typedef struct linknode {
    struct linknode* prev;
    struct linknode* next;
    aoi_object_t* obj;
    int pos;
    shuffle_func shuffle;
    uint8_t flag;
    int8_t order;
} linknode_t;

// 被观察者对象
typedef struct aoi_entity {
    position_t center;  // 中心点坐标
    position_t ocenter; // 中心点坐标(旧)
    linknode_t node[2]; // [0]=x轴链表节点 [1]=z轴链表节点
#ifdef LINKAOI_HAVE_RESTORE_WITNESS
    hash_set_t* witness;
#endif
} aoi_entity_t;

// 观察者对象
typedef struct aoi_trigger {
    position_t center;
    position_t ocenter;
    linknode_t node[4]; //[0]=x轴低边界 [1]=z轴低边界 [2]=x轴高边界 [3]=z轴高边界
    int range;
#ifdef LINKAOI_HAVE_RESTORE_VISIBLE
    hash_set_t* visible;
#endif
} aoi_trigger_t;

// 十字链表上下文
typedef struct aoi_context {
    linknode_t linklist[2]; // 十字链表保存所有对象([0]=x轴链表,[1]=z轴链表,从小到大排序)

    int freenum;            // 回收池数量
    aoi_object_t* freelist; // 回收池

    struct aoi_object enter_list;
    struct aoi_object leave_list;

    callback_func enter_func;
    callback_func leave_func;
    void *ud;
} aoi_context_t;


struct aoi_context* create_aoi_ctx(callback_func enter_func, callback_func leave_func, void* ud);
void release_aoi_ctx(struct aoi_context* ctx);

struct aoi_object* create_aoi_object(struct aoi_context* ctx, int objid);
void release_aoi_object(struct aoi_context* ctx, struct aoi_object* object);

int create_entity(struct aoi_context* ctx, struct aoi_object* object, int x, int z);
int create_trigger(struct aoi_context* ctx, struct aoi_object* object, int x, int z, int range);

int delete_entity(struct aoi_context* ctx, struct aoi_object* object, int shuffle);
int delete_trigger(struct aoi_context* ctx, struct aoi_object* object);

void move_entity(struct aoi_context* ctx, struct aoi_object* object, int x, int z);
void move_trigger(struct aoi_context* ctx, struct aoi_object* object, int x, int z);

void get_witness(struct aoi_context* ctx, struct aoi_object* object, callback_func, void* ud);
void get_visible(struct aoi_context* ctx, struct aoi_object* object, callback_func, void* ud);

void foreach_aoi_entity(struct aoi_context* ctx, foreach_entity_func func, void* ud);
void foreach_aoi_trigger(struct aoi_context* ctx, foreach_trigger_func func, void* ud);


#endif
