-- local pb = require "pb"
-- local protoc = require "protoc"

-- -- load schema from text (just for demo, use protoc.new() in real world)
-- assert(protoc:load [[
--    message Phone {
--       string name        = 1;
--       int64  phonenumber = 2;
--    }
--    message Person {
--       optional string name     = 1;
--       optional int32  age      = 2;
--       optional string address  = 3;
--       repeated Phone  contacts = 4;
--    } ]])

-- -- lua table data
-- local data = {
--    name = "ilse",
--    age  = 18,
--    contacts = {
--       { name = "alice", phonenumber = 12312341234 },
--       { name = "bob",   phonenumber = 45645674567 }
--    }
-- }

-- -- encode lua table data into binary format in lua string and return
-- local bytes = assert(pb.encode("Person", data))
-- local bytes2 = pb.tohex(bytes) --转成16进制
-- gLog.i("bytes==", bytes)
-- gLog.i("bytes2==", bytes2)

-- -- and decode the binary data back into lua table
-- local data2 = assert(pb.decode("Person", bytes))
-- local data3 = require "serpent".block(data2)
-- gLog.dump(data2, "data2=", 10)
-- gLog.dump(data3, "data3=", 10)



 local pb = require ('pb')
 local pc = require('protoc').new()
 assert(pc:load([[
 syntax = "proto3";
 option java_package = "com.protocol.proto";
 option java_outer_classname = "ProtoCommon";
 enum BType{
   ZC = 0;//主城
   QL = 1;//青楼
   QZ = 2;//钱装
 }
 message ClientLoading_Response_101 {
   message Role{
     int64 roleId = 1;//玩家id
     string name = 2;//玩家名
     int32 gender = 3;//性别
   }
   message Building{
     BType bType = 1;//建筑类型
     int32 level = 2;//建筑等级
     int32 profit = 3;//收益速度
     Role role = 4; //玩家模块
   }
   Role role = 1; //玩家模块
   repeated Building building = 2;//多个建筑模块
 }]]))
 
 ---@type ClientLoading_Response_101
 local sendMsg = {}
 sendMsg.building = {{bType = 1, level = 1, profit = 1,{roleId = 1, name = "sss", gender = 1}},  {bType = 2, level = 2, profit = 2}}
 sendMsg.role = {roleId = 1, name = "2232", gender = 2}

 local serDATA = pb.encode("ClientLoading_Response_101", sendMsg)
 
local result = {}
result = pb.decode("ClientLoading_Response_101", serDATA)
gLog.dump(result, "result=", 10)
