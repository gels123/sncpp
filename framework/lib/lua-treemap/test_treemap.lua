-- package.path = "../lualib/?.lua"

local treemap = require "treemap"
-- require "print_r"

local root = treemap.new()
for i = 1, 7 do
  root:put(i, i)
end

print(root:remove(2))

print(root:get(1))

print(root)
print(root:first_entry().value)
print(root:last_entry().value)


-- print_r(root)

--[[

for i = 1, 7 do
  treemap.put(root, i, i .. " ")
end

print_r(root)


print(treemap.get(root, 2))

print(treemap.higher_entry(root, 10) == nil)

print(treemap.lower_entry(root, 2).value)

print(treemap.first_entry(root).value)
print(treemap.last_entry(root).value)
--]]

--[[
local treemap = require "treemap"
local root = treemap.new()

for i = 1, 7 do
  root.put(root, i, {i = i, num = i * 100})
end

gLog.dump(root, "===sdfadf=====", 10)


local entry2 = root.get(root, 2)
gLog.dump(entry2, "===sdfadf== entry2===", 10)

local higher_entry = root.higher_entry(root, 5.5)
gLog.dump(higher_entry, "===sdfadf== higher_entry===", 10)


local first_entry = root.first_entry(root)
gLog.dump(first_entry, "===sdfadf== first_entry===", 10)
local last_entry = root.last_entry(root)
gLog.dump(last_entry, "===sdfadf== last_entry===", 10)
]]

--[[
function x()
  print(1000)
end

local meta_tbl = {}
print(meta_tbl)

function meta_tbl:__index(v)
  print(self, v)
  return x
end

local a = {}
print(a)

local s = setmetatable(a, meta_tbl)

print(s.put(10))
--]]
