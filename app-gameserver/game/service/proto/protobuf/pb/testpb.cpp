//
// Created by gels on 2023/9/13.
// g++ -o testpb.out testpb.cpp test.pb.cc -I./ -lprotobuf -std=c++11
//
#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include "test.pb.h"

int main() {
    testpb::TestPack p;
    p.set_uid(100);
    p.set_name("sam");
    std::string str;
    if (!p.SerializeToString(&str)) {
        std::cout << "SerializeToString fail" << std::endl;
        return 1;
    }
    std::cout << "str=" << str << std::endl;
    testpb::TestPack p2;
    if (!p2.ParseFromString(str)) {
        std::cout << "ParseFromString fail" << std::endl;
        return 1;
    }
    std::cout << "uid=" << p2.uid() << " name =" << p2.name() << std::endl;
    return 0;
}
