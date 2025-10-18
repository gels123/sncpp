#include "hash_witness.h"
#include <assert.h>
#include <stdio.h>

int hash_set_put(hash_set_t *self, int objid) {
	assert(hash_set_has(self, objid) == 0);
	int r;
	kh_put(objid, self, objid, &r);
	return r;
}

int hash_set_has(hash_set_t *self, int objid) {
	khiter_t k = kh_get(objid, self, objid);
	if (k < kh_end(self)) {
		return kh_exist(self, k);
	}
	return 0;
}

void hash_set_del(hash_set_t *self, int objid) {
	assert(hash_set_has(self, objid) == 1);
	khiter_t k = kh_get(objid, self, objid);
	kh_del(objid, self, k);
}