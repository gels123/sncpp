--[[
    一致性哈希
    https:blog.csdn.net/kefengwang/article/details/81628977
]]
local treemap = require("treemap")
local crc32 = require ("crc32")
local chash = require ("chash")
local consistentHash = class("consistentHash")

local VIRTUAL_COPIES = 1024 -- 物理节点至虚拟节点的复制倍数

function consistentHash:ctor()
    -- 哈希值 => 物理节点
    self.virtualNodes = treemap.new()
end

-- 哈希算法
function consistentHash:getHash(key)
    return chash.fnv_hash(tostring(key)) -- crc32.short(tostring(key))
end

-- 添加物理节点
function consistentHash:addPhysicalNode(nodeId)
    nodeId = tostring(nodeId)
    for idx = 1, VIRTUAL_COPIES, 1 do
        local hash = self:getHash(nodeId.."#"..idx)
        print("consistentHash:addPhysicalNode", nodeId, hash)
        self.virtualNodes:put(hash, nodeId)
    end
end

-- 删除物理节点
function consistentHash:removePhysicalNode(nodeId)
    for idx = 1, VIRTUAL_COPIES, 1 do
        local hash = self:getHash(nodeId.."#"..idx)
        self.virtualNodes:remove(hash)
    end
end

-- 查找对象映射的节点
function consistentHash:getObjectNode(objectId)
    local hash = self:getHash(objectId)
    print("consistentHash:getObjectNode objectId=", objectId, "hash=", hash)
    local node = self.virtualNodes:higher_entry(hash)
    if not node then
        node = self.virtualNodes:first_entry()
    end
    if node then
        return node.value
    end
end

-- 统计对象与节点的映射关系
function consistentHash:dumpObjectNodeMap(label, objectIdMin, objectIdMax)
    -- 统计
    local objectNodeMap = {}
    for objectId = objectIdMin, objectIdMax, 1 do
        local nodeId = self:getObjectNode(objectId)
        if not objectNodeMap[nodeId] then
            objectNodeMap[nodeId] = {}
        end
        objectNodeMap[nodeId][objectId] = true
    end
    gLog.dump(objectNodeMap, "consistentHash:dumpObjectNodeMap objectNodeMap=", 10)

    -- 打印
    local totalCount = objectIdMax - objectIdMin + 1
    print("======== " + label + " ========")
    for nodeId,v in pairs() do
        local percent = (100 * table.nums(v) / totalCount)
        print("nodeId=", nodeId, ": RATE=", percent, "%")
    end
end

return consistentHash