#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <stdio.h>

#include "link-aoi.h"

static inline int dt_x_range(position_t* entity, position_t* trigger) {
	return abs(entity->x - trigger->x);
}

static inline int dt_z_range(position_t* entity, position_t* trigger) {
	return abs(entity->z - trigger->z);
}

static inline void insert_node(aoi_context_t* ctx, int axis_x, linknode_t* node) {
	linknode_t* link;
	if (axis_x) {
		link = &ctx->linklist[0]; // [0]=x轴
	} else {
		link = &ctx->linklist[1]; // [1]=z轴
	}
	linknode_t* next = link->next;
	next->prev = node;
	node->next = next;
	node->prev = link;
	link->next = node;
}

static inline void remove_node(linknode_t* node) {
	linknode_t* next = node->next;
	linknode_t* prev = node->prev;
	next->prev = prev;
	prev->next = next;
	node->prev = NULL;
	node->next = NULL;
}

static inline void exchange_node(linknode_t* lhs, linknode_t* rhs) {
	remove_node(lhs);
	linknode_t* next = rhs->next;
	rhs->next = lhs;
	lhs->prev = rhs;
	lhs->next = next;
	next->prev = lhs;
}

static inline void link_enter_list(aoi_context_t* ctx, aoi_object_t* self, aoi_object_t* other, cmp_func cmp, int is_entity) {
	if (other->inout == IN || other->inout == OUT) {
		return;
	}
	if (other->inout == 0) {
		if (is_entity) {
			int in = cmp(&self->entity->center, &other->trigger->center) <= other->trigger->range;
			if (!in) {
                return;
			}
		} else {
			int in = cmp(&other->entity->center, &self->trigger->center) <= self->trigger->range;
			if (!in) {
                return;
			}
		}
	}
	aoi_object_t* prev = ctx->enter_list.prev;
	prev->next = other;
	other->next = &ctx->enter_list;
	other->prev = prev;
	ctx->enter_list.prev = other;

	other->inout = IN;
}

static inline void link_leave_list(aoi_context_t* ctx, aoi_object_t* self, aoi_object_t* other, cmp_func cmp, int is_entity) {
	if (other->inout == OUT) {
		return;
	}
	if (other->inout == IN) {
		aoi_object_t* next = other->next;
		aoi_object_t* prev = other->prev;
		next->prev = prev;
		prev->next = next;

		other->next = other->prev = NULL;
		other->inout = 0;
		return;
	} else {
		if (is_entity) {
			if (cmp(&self->entity->ocenter, &other->trigger->center) > other->trigger->range)
				return;
		} else {
			if (cmp(&other->entity->center, &self->trigger->ocenter) > self->trigger->range) {
				return;
			}
		}
	}

	aoi_object_t* prev = ctx->leave_list.prev;
	prev->next = other;
	other->next = &ctx->leave_list;
	other->prev = prev;
	ctx->leave_list.prev = other;

	other->inout = OUT;
}

static void entity_shuffle_x(aoi_context_t* ctx, linknode_t* node, int x) {
	node->pos = x;
	linknode_t* link = &ctx->linklist[0]; // 双向链表根节点 [0]=x轴 [1]=z轴
	if (link->next == link) {
		return;
	}
	while (node->prev != link && ((node->pos < node->prev->pos) || (node->pos == node->prev->pos && node->order <= node->prev->order))) {
		linknode_t* other = node->prev;
		exchange_node(node->prev, node);

		if (other->flag & AOI_LOW_BOUND) { // 链表为从小到大排序, 往左prev滑动, 滑过最小边界, 离开视野
			link_leave_list(ctx, node->obj, other->obj, dt_z_range, 1);
		} else if (other->flag & AOI_HIGH_BOUND) {
			link_enter_list(ctx, node->obj, other->obj, dt_z_range, 1);
		}
	}
	while (node->next != link && ((node->pos > node->next->pos) || (node->pos == node->next->pos && node->order >= node->next->order))) {
		linknode_t* other = node->next;
		exchange_node(node, node->next);

		if (other->flag & AOI_LOW_BOUND) {
			link_enter_list(ctx, node->obj, other->obj, dt_z_range, 1);
		} else if (other->flag & AOI_HIGH_BOUND) {
			link_leave_list(ctx, node->obj, other->obj, dt_z_range, 1);
		}
	}
}

static void entity_shuffle_z(aoi_context_t* ctx, linknode_t* node, int z) {
	node->pos = z;
	linknode_t* link = &ctx->linklist[1]; // 0=x轴 1=z轴
	if (link->next == link) {
		return;
	}
	while (node->prev != link && ((node->pos < node->prev->pos) || (node->pos == node->prev->pos && node->order <= node->prev->order))) {
		linknode_t* other = node->prev;
		exchange_node(node->prev, node);

		if (other->flag & AOI_LOW_BOUND) {
			link_leave_list(ctx, node->obj, other->obj, dt_x_range, 1);
		} else if (other->flag & AOI_HIGH_BOUND) {
			link_enter_list(ctx, node->obj, other->obj, dt_x_range, 1);
		}
	}
	while (node->next != link && ((node->pos > node->next->pos) || (node->pos == node->next->pos && node->order >= node->next->order))) {
		linknode_t* other = node->next;
		exchange_node(node, node->next);

		if (other->flag & AOI_LOW_BOUND) {
			link_enter_list(ctx, node->obj, other->obj, dt_x_range, 1);
		} else if (other->flag & AOI_HIGH_BOUND) {
			link_leave_list(ctx, node->obj, other->obj, dt_x_range, 1);
		}
	}
}

static void trigger_low_bound_shuffle_x(aoi_context_t* ctx, linknode_t* node, int x) {
	node->pos = x;
	linknode_t* link = &ctx->linklist[0];
	if (link->next == link) {
		return;
	}
	while (node->prev != link && ((node->pos < node->prev->pos) || (node->pos == node->prev->pos && node->order <= node->prev->order))) {
		linknode_t* other = node->prev;
		exchange_node(node->prev, node);
		if (other->flag & AOI_ENTITY) {
			link_enter_list(ctx, node->obj, other->obj, dt_z_range, 0);
		}
	}
	while (node->next != link && ((node->pos > node->next->pos) || (node->pos == node->next->pos && node->order >= node->next->order))) {
		linknode_t* other = node->next;
		exchange_node(node, node->next);
		if (other->flag & AOI_ENTITY) {
			link_leave_list(ctx, node->obj, other->obj, dt_z_range, 0);
		}
	}
}

static void trigger_low_bound_shuffle_z(aoi_context_t* ctx, linknode_t* node, int z) {
	node->pos = z;
	linknode_t* link = &ctx->linklist[1];
	if (link->next == link) {
		return;
	}
	while (node->prev != link && ((node->pos < node->prev->pos) || (node->pos == node->prev->pos && node->order <= node->prev->order))) {
		linknode_t* other = node->prev;
		exchange_node(node->prev, node);
		if (other->flag & AOI_ENTITY) {
			link_enter_list(ctx, node->obj, other->obj, dt_x_range, 0);
		}
	}
	while (node->next != link && ((node->pos > node->next->pos) || (node->pos == node->next->pos && node->order >= node->next->order))) {
		linknode_t* other = node->next;
		exchange_node(node, node->next);
		if (other->flag & AOI_ENTITY) {
			link_leave_list(ctx, node->obj, other->obj, dt_x_range, 0);
		}
	}
}

static void trigger_high_bound_shuffle_x(aoi_context_t* ctx, linknode_t* node, int x) {
	node->pos = x;
	linknode_t* link = &ctx->linklist[0];
	if (link->next == link) {
		return;
	}
	while (node->prev != link && ((node->pos < node->prev->pos) || (node->pos == node->prev->pos && node->order <= node->prev->order))) {
		linknode_t* other = node->prev;
		exchange_node(node->prev, node);
		if (other->flag & AOI_ENTITY) {
			link_leave_list(ctx, node->obj, other->obj, dt_z_range, 0);
		}
	}
	while (node->next != link && ((node->pos > node->next->pos) || (node->pos == node->next->pos && node->order >= node->next->order))) {
		linknode_t* other = node->next;
		exchange_node(node, node->next);
		if (other->flag & AOI_ENTITY) {
			link_enter_list(ctx, node->obj, other->obj, dt_z_range, 0);
		}
	}
}

static void trigger_high_bound_shuffle_z(aoi_context_t* ctx, linknode_t* node, int z) {
	node->pos = z;
	linknode_t* link = &ctx->linklist[1];
	if (link->next == link) {
		return;
	}
	while (node->prev != link && ((node->pos < node->prev->pos) || (node->pos == node->prev->pos && node->order <= node->prev->order))) {
		linknode_t* other = node->prev;
		exchange_node(node->prev, node);
		if (other->flag & AOI_ENTITY) {
			link_leave_list(ctx, node->obj, other->obj, dt_x_range, 0);
		}
	}
	while (node->next != link && ((node->pos > node->next->pos) || (node->pos == node->next->pos && node->order >= node->next->order))) {
		linknode_t* other = node->next;
		exchange_node(node, node->next);
		if (other->flag & AOI_ENTITY) {
			link_enter_list(ctx, node->obj, other->obj, dt_x_range, 0);
		}
	}
}

static void shuffle_entity(aoi_context_t* ctx, aoi_entity_t* entity, int x, int z) {
	entity->ocenter = entity->center;

	entity->center.x = x;
	entity->center.z = z;

	entity->node[0].shuffle(ctx, &entity->node[0], x);
	entity->node[1].shuffle(ctx, &entity->node[1], z);

	aoi_object_t* obj = entity->node[0].obj;

	for (aoi_object_t* node = ctx->enter_list.next; node != &ctx->enter_list;) {
		ctx->enter_func(node->objid, obj->objid, ctx->ud);
#ifdef LINKAOI_HAVE_RESTORE_WITNESS
		hash_set_put(entity->witness, node->objid);
#endif
#ifdef LINKAOI_HAVE_RESTORE_VISIBLE
		hash_set_put(node->trigger->visible, obj->objid);
#endif
		aoi_object_t* tmp = node;
		node = node->next;
		tmp->next = tmp->prev = NULL;
		tmp->inout = 0;
	}
	ctx->enter_list.prev = ctx->enter_list.next = &ctx->enter_list;

	for (aoi_object_t* node = ctx->leave_list.next; node != &ctx->leave_list; ) {
		ctx->leave_func(node->objid, obj->objid, ctx->ud);
#ifdef LINKAOI_HAVE_RESTORE_WITNESS
		hash_set_del(entity->witness, node->objid);
#endif
#ifdef LINKAOI_HAVE_RESTORE_VISIBLE
		hash_set_del(node->trigger->visible, obj->objid);
#endif
		aoi_object_t* tmp = node;
		node = node->next;
		tmp->next = tmp->prev = NULL;
		tmp->inout = 0;
	}
	ctx->leave_list.prev = ctx->leave_list.next = &ctx->leave_list;
}

static void shuffle_trigger(aoi_context_t* ctx, aoi_trigger_t* trigger, int x, int z) {
	trigger->ocenter = trigger->center;

	trigger->center.x = x;
	trigger->center.z = z;

	if (trigger->ocenter.x < x) {
		trigger->node[2].shuffle(ctx, &trigger->node[2], x + trigger->range);
        trigger->node[0].shuffle(ctx, &trigger->node[0], x - trigger->range);
	} else {
		trigger->node[0].shuffle(ctx, &trigger->node[0], x - trigger->range);
		trigger->node[2].shuffle(ctx, &trigger->node[2], x + trigger->range);
	}
	if (trigger->ocenter.z < z) {
		trigger->node[3].shuffle(ctx, &trigger->node[3], z + trigger->range);
		trigger->node[1].shuffle(ctx, &trigger->node[1], z - trigger->range);
	} else {
		trigger->node[1].shuffle(ctx, &trigger->node[1], z - trigger->range);
		trigger->node[3].shuffle(ctx, &trigger->node[3], z + trigger->range);
	}

	aoi_object_t* obj = trigger->node[0].obj;
	for (aoi_object_t* node = ctx->enter_list.next; node != &ctx->enter_list;) {
		ctx->enter_func(obj->objid, node->objid, ctx->ud);
#ifdef LINKAOI_HAVE_RESTORE_WITNESS
		hash_set_put(node->entity->witness, obj->objid);
#endif
#ifdef LINKAOI_HAVE_RESTORE_VISIBLE
		hash_set_put(obj->trigger->visible, node->objid);
#endif
		aoi_object_t* tmp = node;
		node = node->next;
		tmp->next = tmp->prev = NULL;
		tmp->inout = 0;
	}
	ctx->enter_list.prev = ctx->enter_list.next = &ctx->enter_list;

	for (aoi_object_t* node = ctx->leave_list.next; node != &ctx->leave_list;) {
		ctx->leave_func(obj->objid, node->objid, ctx->ud);
#ifdef LINKAOI_HAVE_RESTORE_WITNESS
		hash_set_del(node->entity->witness, obj->objid);
#endif
#ifdef LINKAOI_HAVE_RESTORE_VISIBLE
		hash_set_del(obj->trigger->visible, node->objid);
#endif
		aoi_object_t* tmp = node;
		node = node->next;
		tmp->next = tmp->prev = NULL;
		tmp->inout = 0;
	}
	ctx->leave_list.prev = ctx->leave_list.next = &ctx->leave_list;
}

int create_entity(aoi_context_t* ctx, aoi_object_t* object, int x, int z) {
	if (object->entity) {
		return -1;
	}
	object->entity = malloc(sizeof(aoi_entity_t));
	memset(object->entity, 0, sizeof(aoi_entity_t));

#ifdef LINKAOI_HAVE_RESTORE_WITNESS
	object->entity->witness = hash_set_new();
#endif
	object->entity->center.x = UNLIMITED;
	object->entity->center.z = UNLIMITED;

	object->entity->node[0].obj = object;
	object->entity->node[1].obj = object;

	object->entity->node[0].flag |= AOI_ENTITY;
	object->entity->node[1].flag |= AOI_ENTITY;

	object->entity->node[0].shuffle = entity_shuffle_x;
	object->entity->node[1].shuffle = entity_shuffle_z;

	object->entity->node[0].order = 0;
	object->entity->node[1].order = 0;

	object->entity->node[0].pos = UNLIMITED;
	object->entity->node[1].pos = UNLIMITED;

	insert_node(ctx, 1, &object->entity->node[0]);
	insert_node(ctx, 0, &object->entity->node[1]);

	shuffle_entity(ctx, object->entity, x, z);
	return 0;
}

int create_trigger(aoi_context_t* ctx, aoi_object_t* object, int x, int z, int range) {
	if (object->trigger) {
		return -1;
	}
	object->trigger = malloc(sizeof(aoi_trigger_t));
	memset(object->trigger, 0, sizeof(aoi_trigger_t));

#ifdef LINKAOI_HAVE_RESTORE_VISIBLE
	object->trigger->visible = hash_set_new();
#endif

	object->trigger->range = range;

	object->trigger->center.x = UNLIMITED;
	object->trigger->center.z = UNLIMITED;

	object->trigger->node[0].obj = object;
	object->trigger->node[1].obj = object;
	object->trigger->node[2].obj = object;
	object->trigger->node[3].obj = object;

	object->trigger->node[0].shuffle = trigger_low_bound_shuffle_x;
	object->trigger->node[1].shuffle = trigger_low_bound_shuffle_z;
	object->trigger->node[2].shuffle = trigger_high_bound_shuffle_x;
	object->trigger->node[3].shuffle = trigger_high_bound_shuffle_z;

	object->trigger->node[0].flag |= AOI_LOW_BOUND;
	object->trigger->node[1].flag |= AOI_LOW_BOUND;

	object->trigger->node[0].order = -2;
	object->trigger->node[1].order = -2;

	object->trigger->node[0].pos = UNLIMITED;

	object->trigger->node[1].pos = UNLIMITED;

	object->trigger->node[2].flag |= AOI_HIGH_BOUND;
	object->trigger->node[3].flag |= AOI_HIGH_BOUND;

	object->trigger->node[2].order = 2;
	object->trigger->node[3].order = 2;

	object->trigger->node[2].pos = UNLIMITED;

	object->trigger->node[3].pos = UNLIMITED;

	insert_node(ctx, 1, &object->trigger->node[0]);
	insert_node(ctx, 1, &object->trigger->node[2]);

	insert_node(ctx, 0, &object->trigger->node[1]);
	insert_node(ctx, 0, &object->trigger->node[3]);

	shuffle_trigger(ctx, object->trigger, x, z);

	return 0;
}

int delete_entity(aoi_context_t* ctx, aoi_object_t* object, int shuffle) {
	if (!object->entity) {
		return -1;
	}
	if (shuffle) {
		shuffle_entity(ctx, object->entity, UNLIMITED, UNLIMITED);
	}

	remove_node(&object->entity->node[0]);
	remove_node(&object->entity->node[1]);

#ifdef LINKAOI_HAVE_RESTORE_WITNESS
    if (object->entity->witness) {
        hash_set_free(object->entity->witness);
        object->entity->witness = NULL;
    }
#endif
    if (object->entity) {
        free(object->entity);
        object->entity = NULL;
    }

	return 0;
}

int delete_trigger(aoi_context_t* ctx, aoi_object_t* object) {
	if (!object->trigger) {
		return -1;
	}
	remove_node(&object->trigger->node[0]);
	remove_node(&object->trigger->node[2]);

	remove_node(&object->trigger->node[1]);
	remove_node(&object->trigger->node[3]);

#ifdef LINKAOI_HAVE_RESTORE_VISIBLE
	if (object->trigger->visible) {
        hash_set_free(object->trigger->visible);
        object->trigger->visible = NULL;
	}
#endif
    if (object->trigger) {
        free(object->trigger);
        object->trigger = NULL;
	}

	return 0;
}

void move_entity(aoi_context_t* ctx, aoi_object_t* object, int x, int z) {
	shuffle_entity(ctx, object->entity, x, z);
}

void move_trigger(aoi_context_t* ctx, aoi_object_t* object, int x, int z) {
	shuffle_trigger(ctx, object->trigger, x, z);
}

aoi_context_t* create_aoi_ctx(callback_func enter_func, callback_func leave_func, void* ud) {
	aoi_context_t* ctx = malloc(sizeof(*ctx));
	memset(ctx, 0, sizeof(*ctx));
	ctx->linklist[0].prev = ctx->linklist[0].next = &ctx->linklist[0];
	ctx->linklist[1].prev = ctx->linklist[1].next = &ctx->linklist[1];
	ctx->enter_list.prev = ctx->enter_list.next = &ctx->enter_list;
	ctx->leave_list.prev = ctx->leave_list.next = &ctx->leave_list;
	ctx->enter_func = enter_func;
	ctx->leave_func = leave_func;
	ctx->ud = ud;
	return ctx;
}

void release_aoi_ctx(aoi_context_t* ctx) {
    linknode_t* tmp = NULL;
    linknode_t* link = &ctx->linklist[0];
    for (linknode_t* node = link->next; node && node != link;) {
        tmp = node->next;
        release_aoi_object(ctx, node->obj);
        node = tmp;
    }
    link->next = link->prev = link;

    tmp = NULL;
    link = &ctx->linklist[1];
    for (linknode_t* node = link->next; node && node != link;) {
        tmp = node->next;
        release_aoi_object(ctx, node->obj);
        node = tmp;
    }

    if (ctx->freelist) {
        aoi_object_t* obj = NULL;
        while(ctx->freelist) {
            obj = ctx->freelist;
            ctx->freelist = obj->next;
            free(obj);
        }
    }
	free(ctx);
}

inline aoi_object_t* create_aoi_object(aoi_context_t* ctx, int objid) {
	aoi_object_t* object = NULL;
	if (ctx->freelist) {
		object = ctx->freelist;
		ctx->freelist = object->next;
        ctx->freenum--;
	} else {
		object = malloc(sizeof(*object));
	}
	memset(object, 0, sizeof(*object));
	object->objid = objid;

	return object;
}

void release_aoi_object(aoi_context_t* ctx, aoi_object_t* object) {
	delete_trigger(ctx, object);
	delete_entity(ctx, object, 0);
	if (ctx->freenum < 2000) {
        object->next = ctx->freelist;
        ctx->freelist = object;
        ctx->freenum++;
	} else {
        free(object);
	}
}

void get_witness(aoi_context_t* ctx, aoi_object_t* object, callback_func func, void* ud) {
#ifdef LINKAOI_HAVE_RESTORE_WITNESS
    if(object->entity && object->entity->witness) {
        for (khiter_t k = kh_begin(object->entity->witness); k < kh_end(object->entity->witness); ++k) {
            if (!kh_exist(object->entity->witness, k))
                continue;
            int other = kh_key(object->entity->witness, k);
            func(object->objid, other, ud);
        }
    }
#endif
}

void get_visible(aoi_context_t* ctx, aoi_object_t* object, callback_func func, void* ud) {
#ifdef LINKAOI_HAVE_RESTORE_VISIBLE
    if(object->trigger && object->trigger->visible) {
        for (khiter_t k = kh_begin(object->trigger->visible); k < kh_end(object->trigger->visible); ++k) {
            if (!kh_exist(object->trigger->visible, k))
                continue;
            int other = kh_key(object->trigger->visible, k);
            func(object->objid, other, ud);
        }
    }
#endif
}

void foreach_aoi_entity(aoi_context_t* ctx, foreach_entity_func func, void* ud) {
	linknode_t* link = &ctx->linklist[0];
	for (linknode_t* node = link->next; node != link; node = node->next) {
		if (node->flag & AOI_ENTITY) {
			aoi_object_t* object = node->obj;
			func(object->objid, object->entity->center.x, object->entity->center.z, ud);
		}
	}
}

void foreach_aoi_trigger(aoi_context_t* ctx, foreach_trigger_func func, void* ud) {
	linknode_t* link = &ctx->linklist[0];
	for (linknode_t* node = link->next; node != link; node = node->next) {
		if (node->flag & AOI_LOW_BOUND) {
			aoi_object_t* object = node->obj;
			func(object->objid, object->trigger->center.x, object->trigger->center.z, object->trigger->range, ud);
		}
	}
}