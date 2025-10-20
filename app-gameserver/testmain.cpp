//
// Created by gels on 2023/6/26.
// g++ -o out -I./game/service/proto/protobuf/src testmain.cpp -L/usr/local/lib ./game/service/proto/protobuf/src/pvplogin.pb.cc -lpthread -lprotobuf -std=c++11
//
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <string.h>
//#include "pvplogin.pb.h"

struct skynet_message {
    uint32_t source;
    int session;
    void * data;
    size_t sz;
};

int main() {
//    int *p  = new int(100);
//    fprintf(stdout, "=================== %d\n", sizeof(*p));
//    pvp::PvpLogin l;
//    l.set_uid(1200);
//
//    std::string out;
//    if (l.SerializeToString(&out)) {
//        fprintf(stdout, "====SerializeToString==ok=\n");
//    } else {
//        fprintf(stdout, "====SerializeToString==err=\n");
//    }
//
//    pvp::PvpLogin l2;
//    l2.ParseFromString(out);
//
//    fprintf(stdout, "------------sdfsdf--%d\n", l2.uid());

//    int data = 100;
//    struct skynet_message a;
//    a.source=1;
//    a.session = 2;
//    a.data = &data;
//    a.sz = 3;
//
//    struct skynet_message *b = (struct skynet_message *)malloc(sizeof(struct skynet_message));
//    memset(b, 0, sizeof(*b));
//    *b = a;

    int num = 511;
    void *p = (void*) &num;
    int64_t pp = (int64_t) p;
    printf("num=%d &num=%p\n", num, &num);
    printf("*p=%d p=%p\n", *((int*)p), p);
    printf("*pp=%d pp=%p\n", *((int*)pp), pp);



    return 0;
}
