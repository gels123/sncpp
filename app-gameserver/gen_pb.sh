#!/bin/sh
./game/service/proto/protobuf/google/protoc/protoc --proto_path=./game/service/proto/protobuf/proto --cpp_out=./game/service/proto/protobuf/pb test.proto