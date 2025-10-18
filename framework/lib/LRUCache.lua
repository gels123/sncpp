--local Node = {
--    key = -1,
--    value = -1,
--    preNode = nil,
--    nextNode = nil,
--}

local LRUCache = {}

function LRUCache:New(capacity)
	local object = setmetatable({}, self)
	self.__index = self
	
    -- 在创建self的时候
    -- self 下的元素类似于类静态变量
    -- object 下的元素类似于对象的成员变量
	object.maxSize = capacity
    object.key2Node = {}
    object.cacheHead = nil
    object.cacheTail = nil
    object.count = 0
	
	return object
end

function LRUCache:SetMaxSize(maxSize)
    if maxSize > 0 then
        self.maxSize = maxSize
    end
end

function LRUCache:SetRemoveCallback(func)
    self.removeFunc = func
end

function LRUCache:Check(key)
    if not self.cacheHead then
        return
    end
    local node = self.key2Node[key]
    if node then
        return node.value
    end
end

function LRUCache:GetAll()
    return self.key2Node
end

function LRUCache:Get(key)
    if not self.cacheHead then
        return
    end
    local node = self.key2Node[key]
    if not node then
        return
    else
        self:PushFront(node)
    end
    return self.cacheHead.value
end

function LRUCache:Set(key, value, bForce)
    if self.maxSize<1 then
        return
    end
    
    if bForce then
        self.maxSize = self.maxSize + 1
    end

    -- 回调缓存
    local callbackCache = {}

    if not self.cacheHead then
        local node = {
            key = key,
            value = value,
        }
        self.key2Node[key] = node
        self.cacheHead = node
        self.cacheTail = self.cacheHead
        self.count = self.count + 1
    else
        local node = self.key2Node[key]
        if not node then
            if self.count==self.maxSize and self.cacheHead and self.cacheHead==self.cacheTail then
                table.insert(callbackCache, {key = self.cacheTail.key, value = self.cacheTail.value})
                
                self.key2Node[self.cacheHead.key] = nil
                self.cacheHead.key = key
                self.cacheHead.value = value
                self.key2Node[key] = self.cacheHead
            else
                while self.count>=self.maxSize do
                    table.insert(callbackCache, {key = self.cacheTail.key, value = self.cacheTail.value})
                    
                    self.key2Node[self.cacheTail.key] = nil
                    self.cacheTail.preNode.nextNode = nil
                    self.cacheTail = self.cacheTail.preNode
                    self.count = self.count -1
                end
                local node = {
                    key = key,
                    value = value,
                    nextNode = self.cacheHead,
                    preNode = nil,
                }
                self.cacheHead.preNode = node
                self.cacheHead = node
                self.key2Node[key] = node
                self.count = self.count + 1
            end
        else
            node.value = value
            self:PushFront(node)
        end
    end

    -- 执行所有回调
    for _, node in ipairs(callbackCache) do
        self:executeRemoveFunc(node)
    end
end

function LRUCache:PushFront(node)
    if node==self.cacheHead then
        return
    end
    if node==self.cacheTail then
        self.cacheTail = node.preNode
    end
    node.preNode.nextNode = node.nextNode
    if node.nextNode then
        node.nextNode.preNode = node.preNode
    end
    node.nextNode = self.cacheHead
    node.preNode = nil
    self.cacheHead.preNode = node
    self.cacheHead = node
end

function LRUCache:Remove(key)
    if not self.cacheHead then
        return
    end
    local node = self.key2Node[key]
    if not node then
        return
    end
    if node==self.cacheHead then
        self.cacheHead = node.nextNode
    end
    if node==self.cacheTail then
        self.cacheTail = node.preNode
    end
    if node.nextNode then
        node.nextNode.preNode = node.preNode
    end
    if node.preNode then
        node.preNode.nextNode = node.nextNode
    end
    self.key2Node[key] = nil
    self.count = self.count - 1
    return node.value
end


function LRUCache:PrintCache()
    local node = self.cacheHead
    while node do
        print(node.key.." = "..node.value)
        node = node.nextNode
    end
    print("------------------------------")
end

function LRUCache:executeRemoveFunc(node)
    if self.removeFunc then
        self.removeFunc(node.key, node.value)
    end
end

function LRUCache:GetCount()
    return self.count
end

return LRUCache

--[[
-- test
local caches = {}
for i=-1,3 do
    caches[i] = LRUCache:New(i)
    print(caches[i].count,caches[i].maxSize)
    caches[i]:Set(1,1)
    caches[i]:PrintCache()
    caches[i]:Set(2,2)
    caches[i]:PrintCache()
    caches[i]:Set(3,3)
    caches[i]:PrintCache()
    caches[i]:Set(4,4)
    caches[i]:PrintCache()
    caches[i]:Get(4)
    if i==3 then
        caches[i]:SetMaxSize(-2)
        caches[i]:Set(5,5)
        print('xxx')
        caches[i]:PrintCache()
    end
end

-- 树形打印table
local print = print
local tconcat = table.concat
local tinsert = table.insert
local srep = string.rep
local type = type
local pairs = pairs
local tostring = tostring
local next = next

function print_r(root)
    local cache = {  [root] = "." }
    local function _dump(t,space,name)
        local temp = {}
        for k,v in pairs(t) do
            local key = tostring(k)
            if cache[v] then
                tinsert(temp,"+" .. key .. " {" .. cache[v].."}")
            elseif type(v) == "table" then
                local new_key = name .. "." .. key
                cache[v] = new_key
                tinsert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. srep(" ",#key),new_key))
            else
                tinsert(temp,"+" .. key .. " [" .. tostring(v).."]")
            end
        end
        return tconcat(temp,"\n"..space)
    end
    print(_dump(root, "",""))
end
local a = LRUCache:New(5)
local b = LRUCache:New(10)
a:Set(1,{x=1,y=2})
b:Set(1,{z=1,x=2})
print_r(a.key2Node)
print('xxxxxxxxxxxxxxxxxxxxx')
print_r(b.key2Node)
]]--
