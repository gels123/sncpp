--- The PathFinder class
local Utils     = require ("core.utils")
local Heuristic = require ("core.heuristics")

-- Internalization
local pairs = pairs
local assert = assert
local type = type

--- Finders (search algorithms implemented). Refers to the search algorithms actually implemented in Jumper.
local Finders = {
  ['THETASTAR'] = require ("core.thetastar"),
}

--- The `PathFinder` class.
local PathFinder = class("PathFinder")

function PathFinder:ctor(grid, finderName, walkable)
  -- Will keep track of all nodes expanded during the search to easily reset their properties for the next pathfinding call
  self.toClear = {}

  self:setGrid(grid)
  self:setFinder(finderName or "ASTAR")
  self:setWalkable(walkable)
  self:setHeuristic("EUCLIDIAN") --CARDINTCARD
end


--- Sets the `grid`. Defines the given `grid` as the one on which the `PathFinder` will perform the search.
function PathFinder:setGrid(grid)
  -- assert(Utils.inherits(grid, Grid), 'Wrong argument #1. Expected a \'grid\' object')
  self._grid = grid
  self._grid._eval = (self._walkable and type(self._walkable) == 'function')
  return self
end

--- Sets the __walkable__ value or function.
function PathFinder:setWalkable(walkable)
  assert(Utils.matchType(walkable,'stringintfunctionnil'), ('Wrong argument #1. Expected \'string\', \'number\' or \'function\', got %s.'):format(type(walkable)))
  self._walkable = walkable
  self._grid._eval = (self._walkable and type(self._walkable) == 'function')
end

--- Returns the `grid`. This is a reference to the actual `grid` used by the `PathFinder`.
function PathFinder:getGrid()
  return self._grid
end

--- Gets the __walkable__ value or function.
function PathFinder:getWalkable()
  return self._walkable
end

--- Defines the `finder`. It refers to the search algorithm used by the `PathFinder`.
function PathFinder:setFinder(finderName)
  assert(Finders[finderName],'Not a valid finder name!')
  self._finder = finderName
  return self
end

--- Returns the name of the `finder` being used.
function PathFinder:getFinder()
  return self._finder
end

--- Sets a heuristic. This is a function internally used by the `PathFinder` to find the optimal path during a search.
function PathFinder:setHeuristic(heuristic)
  assert(Heuristic[heuristic] or (type(heuristic) == 'function'), 'Not a valid heuristic!')
  self._heuristic = Heuristic[heuristic] or heuristic
  return self
end

--- Returns the `heuristic` used. Returns the function itself.
function PathFinder:getHeuristic()
  return self._heuristic
end

--- Calculates a `path`. Returns the `path` from location __[startX, startY]__ to location __[endX, endY]__.
function PathFinder:getPath(startX, startY, endX, endY, aid)
  self:reset()
  local startNode = self._grid:getNodeAt(startX, startY)
  local endNode = self._grid:getNodeAt(endX, endY)
  --
  if not startNode or not endNode then
    return
  end
  --
  if not self._grid:isWalkable(endX, endY) then
    return
  end
  --
  local lastNode = Finders[self._finder]:getPath(self, startNode, endNode, aid)
  if lastNode then
    return Utils.traceBackPath(self, lastNode, startNode)
  end
end

--- Resets the `PathFinder`. This function is called internally between successive pathfinding calls, so you should not
function PathFinder:reset()
  if next(self.toClear) then
    for node,_ in pairs(self.toClear) do
      node:reset()
    end
    self.toClear = {}
  end
end

-- Returns PathFinder class
return PathFinder