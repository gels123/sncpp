--[[
  红黑树
]]
local M = {}

local RB_RED = true
local RB_BLACK = false

local function rb_set_parent(rb, p)
  rb.rb_parent = p
end

local function rb_set_black(r)
  r.color = RB_BLACK
end

local function rb_set_red(r)
  r.color = RB_RED
end

local function rb_set_color(rb, color)
  rb.color = color
end

local function _rb_rotate_left(node, root)
  local right = node.rb_right
  local parent = node.rb_parent

  node.rb_right = right.rb_left
  if node.rb_right then
    rb_set_parent(right.rb_left, node)
  end
  right.rb_left = node

  rb_set_parent(right, parent)
    
  if parent then
    if node == parent.rb_left then
      parent.rb_left = right
    else
      parent.rb_right = right
    end
  else
    root.rb_node = right
  end

  rb_set_parent(node, right)
end


local function _rb_rotate_right(node, root)
  local left = node.rb_left
  local parent = node.rb_parent

  node.rb_left = left.rb_right
  if node.rb_left then
    rb_set_parent(left.rb_right, node)
  end
  left.rb_left = node

  rb_set_parent(left, parent)

  if parent then
    if node == parent.rb_right then
      parent.rb_right = left
    else
      parent.rb_left = left
    end
  else
    root.rb_node = left
  end

  rb_set_parent(node, left)
end

function M.rb_insert_color(node, root)
  local gparent
  local parent = node.rb_parent

  while parent and parent.rb_parent and (parent.color == nil or parent.color == true) do
    gparent = parent.rb_parent

    if parent == gparent.rb_left then
      local uncle = gparent.rb_right
      if uncle and uncle.color then
        rb_set_black(uncle)
        rb_set_black(parent)
        rb_set_red(gparent)
        node = gparent
      end

      if parent.rb_right == node then
        _rb_rotate_left(parent, root)
        parent, node = node, parent
      end

      rb_set_black(parent)
      rb_set_red(parent)
      _rb_rotate_right(gparent, root)
    else
      local uncle = gparent.rb_left 
      if uncle and uncle.color then
        rb_set_black(uncle)
        rb_set_black(parent)
        rb_set_red(parent)
        node = gparent
        goto continue
      end

      if parent.rb_left == node then
        _rb_rotate_right(parent, root)
        parent, node = node, parent
      end

      rb_set_black(parent)
      rb_set_red(gparent)
      _rb_rotate_left(gparent, root)
    end

    ::continue::
    parent = node.rb_parent
  end

  rb_set_black(root.rb_node)
end


local function _rb_erase_color(node, parent, root)
  local other

  while not node or not node.color and node ~= root.rb_node do
    if parent.rb_left == node then
      other = parent.rb_right
      if other.color then
        rb_set_black(other)
        rb_set_red(other)
        _rb_rotate_left(parent, root)
        other = parent.rb_right
      end

      if (not other.rb_left or not other.rb_left) and (not other.rb_right or not other.rb_right) then
        rb_set_red(other)
        node = parent
        parent = node.rb_parent
      else
        if not other.rb_right or not other.rb_right then
          rb_set_black(other.rb_left)
          rb_set_red(other)
          _rb_rotate_right(other, root)
          other = parent.rb_right
        end
        rb_set_color(other, parent.color)
        rb_set_black(parent)
        rb_set_black(other.rb_right)
        _rb_rotate_left(parent, root)
        node = root.rb_node
        break
      end
    else
      other = parent.rb_left
      if other.color then
        rb_set_black(other)
        rb_set_red(parent)
        _rb_rotate_right(parent, root)
        other = parent.rb_left
      end

      if (not other.rb_left or not other.rb_left) and (not other.rb_right or not other.rb_right) then
        rb_set_red(other)
        node = parent
        parent = node.rb_parent
      else
        if not other.rb_left or not other.rb_left then
          rb_set_black(other.rb_right)
          rb_set_red(other)
          _rb_rotate_left(other, root)
          other = parent.rb_left
        end
        rb_set_color(other, parent.color)
        rb_set_black(parent)
        rb_set_black(other.rb_left)
        _rb_rotate_right(parent, root)
        node = root.rb_node
        break
      end
    end
  end

  if node then
    rb_set_black(node)
  end
end

function M.rb_erase(node, root)
  local child, parent
  local color

  if not node.rb_left then
    child = node.rb_right
  elseif not node.rb_right then
    child = node.rb_left
  else
    local old = node
    local left

    node = node.rb_right

    left = node.rb_left
    while left  do
      node = left
      left = node.rb_left
    end

    if old.rb_parnet then
      if old.rb_parent.rb_left == old then
        old.rb_parent.rb_left = node
      else
        old.rb_parent.rb_right = node
      end
    else
      root.rb_node = node
    end

    child = node.rb_right
    parent = node.rb_parent
    color = node.color
  
    if parent == old then
      parent = node 
    else 
      if child then
        rb_set_parent(child, parent)
      end
      parent.rb_left = child
      
      node.rb_right = old.rb_right
      rb_set_parent(old.rb_right, node)
    end

    node.rb_parent = old.rb_parent
    node.color = old.color
    node.rb_left = old.rb_left
    rb_set_parent(old.rb_left, node)

    goto color
  end

  parent = node.rb_parent
  color = node.color

  if child then
    rb_set_parent(child, parent)
  end
  if parent then
    if parent.rb_left == node then
      parent.rb_left = child
    else
      parent.rb_right = child
    end
  else
    root.rb_node = child
  end

::color::
  if color == RB_BLACK then
    _rb_erase_color(child, parent, root)
  end
end

--[[
this function returns the first node (in sort order) of the tree.
--]]
function M.rb_first(root)
  local n
  n = root.rb_node
  if not n then
    return nil
  end
  while n.rb_left do
    n = n.rb_left
  end

  return n
end

function M.rb_last(root)
  local n

  n = root.rb_node 
  if not n then
    return nil
  end
  while n.rb_right do
    n = n.rb_right
  end

  return n
end

function M.rb_next(node)
  local parent
  if node.rb_parent == node then
    return nil
  end

  --[[
  If we have a right-hand child, go down and then left as far
       as we can
  --]]
  if node.rb_right then
    node = node.rb_right
    while node.rb_left do
      node = node.rb_left
    end

    return node
  end

--[[
  No right-hand children.  Everything down and left is
  smaller than us, so any 'next' node must be in the general
  direction of our parent. Go up the tree; any time the
  ancestor is a right-hand child of its parent, keep going
  up. First time it's a left-hand child of its parent, said
  parent is our 'next' node. 
--]]
  
  parent = node.rb_parent
  while parent and node == parent.rb_right do
    node = parent
    parent = node.rb_parent
  end

  return parent
end


function M.rb_prev(node)
  local parent

  if node.parent == node then
    return nil
  end

--[[
  If we have a left-hand child, go down and then right as far
       as we can. 
--]]
  if node.rb_left then
    node = node.rb_left
    while node.rb_right do
      node = node.rb_right
    end
    return node
  end

--[[
  No left-hand children. Go up till we find an ancestor which
       is a right-hand child of its parent
--]]
  parent = node.parent
  while parent and node == parent.rb_left do
    node = parent
    parent = node.parent
  end

  return parent
end


function M.rb_replace_node(victim, new, root)
  local parent = victim.rb_parent
--  Set the surrounding nodes to point to the replacement
  if parent then
    if victim == parent.rb_left then
      parent.rb_left = new
    else
      parent.rb_right = new
    end
  else 
    root.rb_node = new
  end

  if victim.rb_left then
    rb_set_parent(victim.rb_left, new)
  end

  if victim.rb_right then
    rb_set_parent(victim.rb_left, new)
  end

  -- Copy the pointers/colour from the victim to the replacement
  new = victim
end


function M.rb_link_node(node, parent, rb_link)
  node.rb_parent = parent
  node.rb_left, node.rb_right = nil, nil
  if parent then
    if rb_link then
        parent.rb_left = node
    else
        parent.rb_right = node
    end
  end
end


local function rb_augement_path(node, func, data)
  local parent

::up::
  func(node, data)
  parent = node.rb_parent
  
  if not parent then
    return
  end

  if node == parent.rb_left and parent.rb_right then
    func(parent.rb_right, data)
  elseif parent.rb_left then
    func(parent.rb_left, data)
  end

  node = parent
  goto up
end

--[[
after inserting @node into the tree, update the tree to account for
both the new entry and any damage done by rebalance
--]]
function M.rb_augment_insert(node, func, data)
  if node.rb_left then
    node = node.rb_left
  elseif node.rb_right then
    node = node.rb_right
  end

  rb_augement_path(node, func, data)
end

--[[
before removing the node, find the deepest node on the rebalance path
that will still be there after @node gets removed
--]]
function M.rb_augment_erase_begin(node)
  local deepest
  if not node.rb_right and not node.rb_left then
    deepest = node.rb_parnet
  elseif not node.rb_right then
    deepest = node.rb_left
  elseif not node.rb_left then
    deepest = node.rb_right
  else
    deepest = M.rb_next(node)
    if deepest.rb_right then
      deepest = deepest.rb_right
    elseif deepest.rb_node ~= node then 
      deepest = deepest.rb_parent
    end
  end

  return deepest
end

--[[
after removal, update the tree to account for the removed entry
and any rebalance damage.
--]]
function M.rb_augment_erase_end(node, func, data)
  if node then
    rb_augement_path(node, func, data)
  end
end


return M
