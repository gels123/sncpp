#include "khash.h"


KHASH_SET_INIT_INT64(objid)

typedef khash_t(objid) hash_set_t;

#define hash_set_new() kh_init(objid)
#define hash_set_free(self) kh_destroy(objid, self)

#define hash_set_foreach(self, block) { \
	int val; \
	for (khiter_t k = kh_begin(self); k < kh_end(self); ++k) {\
	    if (!kh_exist(self, k)) continue; \
		val = kh_key(self, k); \
		block; \
    } \
}
int hash_set_put(hash_set_t *self, int);
int hash_set_has(hash_set_t *self, int);
void hash_set_del(hash_set_t *self, int);