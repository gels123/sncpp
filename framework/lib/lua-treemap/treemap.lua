--[[
  红黑树-图
]]
local rbtree = require "rbtree"
local assert = assert

local M = {}
local _treemap_meta = {}


function _treemap_meta.__index(tbl, key)
  return _treemap_meta[key]
end

--[[
function _treemap_meta.__newindex(tbl, key, value)
  rawset(tbl, key, value)
end
--]]

function M.new()
  return setmetatable({}, _treemap_meta)
end


function _treemap_meta.put(root, k, v)
  assert(root and k and v)

  local t = root.rb_node
  local parent
  local new_node = {["key"] = k,  ["value"] = v}
  
  local cmp = false
  while t do
    parent = t
    if k < t.key then
      t = t.rb_left
      cmp = true
    elseif k > t.key then
      cmp = false
      t = t.rb_right
    else 
      t.value = v
      return 
    end
  end

  rbtree.rb_link_node(new_node, parent, cmp)
  if not parent then
    root.rb_node = new_node
  end

  rbtree.rb_insert_color(new_node, root)
end

function _treemap_meta.get(root, k)
  local p = root.rb_node
  while p do
    if k < p.key then
      p = p.rb_left
    elseif k > p.key then
      p = p.rb_right
    else
      return p
    end
  end
  return nil
end


function _treemap_meta.remove(root, k)
  local entry = _treemap_meta.get(root, k)
  if entry then
    rbtree.rb_erase(entry, root)
    return true
  end
  return false
end


function _treemap_meta.higher_entry(root, k)
  local p = root.rb_node
  while p do
    local cmp = k - p.key
    if cmp < 0 then
      if p.rb_left then
        p = p.rb_left
      else
        return p
      end
    else
      if p.rb_right then
        p = p.rb_right
      else
        local parent = p.rb_parent
        local ch = p
        while parent and ch == parent.rb_right do
          ch = parent
          parent = parent.rb_parent
        end
        return parent
      end
    end
  end
  return nil
end


function _treemap_meta.lower_entry(root, k)
  local p = root.rb_node
  while p do
    local cmp = k - p.key
    if cmp > 0 then
      if p.rb_right then
        p = p.rb_rgiht
      else
        return p
      end
    else
      if p.rb_left then
        p = p.rb_left
      else
        local parent = p.rb_parent
        local ch = p
        while parent and ch == parent.rb_left do
          ch = parent
          parent = parent.rb_parent
        end

        return parent
      end
    end
  end
end

function _treemap_meta.first_entry(root)
  return rbtree.rb_first(root)
end

function _treemap_meta.last_entry(root)
  return rbtree.rb_last(root)
end

return M
