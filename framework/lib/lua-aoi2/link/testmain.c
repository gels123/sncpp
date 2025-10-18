//
// Created by gels on 2023/6/14.
//

#include <stdio.h>
#include <stdlib.h>
#include "hash_witness.h"
#include "link-aoi.h"

#define block printf("===kk==%d\n", val);

//int main() {
//    printf("============sdfad====\n");
//    hash_set_t* witness;
//    witness = hash_set_new();
//
//    hash_set_put(witness, 101);
//    hash_set_put(witness, 102);
//    hash_set_put(witness, 103);
//
////    for (khiter_t k = kh_begin(witness); k < kh_end(witness); ++k) {
////	    if (!kh_exist(witness, k)) {
////            continue;
////	    }
////		int kk = kh_key(witness, k);
////        printf("===kk==%d\n", kk);
////    }
//    hash_set_foreach(witness, block)
//
//    hash_set_free(witness);
//
//    return 0;
//}

//#include "khash.h"
//KHASH_MAP_INIT_INT(32, char)
//int main() {
//    int ret, is_missing;
//    khash_t(32) *h = kh_init(32);
//    khiter_t k = kh_put(32, h, 5, &ret);
//    printf("0===ret=%d kk=%d cc=%d\n", ret, kh_key(h, k), kh_value(h, k));
//    kh_value(h, k) = 10;
//    printf("1===ret=%d kk=%d cc=%d\n", ret, kh_key(h, k), kh_value(h, k));
//    k = kh_get(32, h, 10);
//    is_missing = (k == kh_end(h));
//    printf("2===is_missing=%d\n", is_missing);
////    k = kh_get(32, h, 5);
////    kh_del(32, h, k);
//    for (k = kh_begin(h); k != kh_end(h); ++k)
//        if (kh_exist(h, k)) {
//            kh_value(h, k) = 1;
//            printf("3=== kk=%d cc=%d\n", kh_key(h, k), kh_value(h, k));
//        }
//
//    kh_destroy(32, h);
//    return 0;
//}

struct user_data2 {
    int b;
    int i[2];
//    lua_State *L;
};

int main() {
    printf("============sdfad====\n");

//    struct aoi_context* ctx = create_aoi_ctx();
//    release_aoi_ctx(ctx);

    struct user_data2 ud = {0, {0, 0,}};
    printf("=========1111== %d %d %d\n", ud.b, ud.i[0], ud.i[1]);

    ud = {1, {1, 1,}};
    printf("=========222== %d %d %d\n", ud.b, ud.i[0], ud.i[1]);

    return 0;
}