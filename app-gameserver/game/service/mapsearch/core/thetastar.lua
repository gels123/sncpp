-- ThetaStar implementation
-- See: http://aigamedev.com/open/tutorials/theta-star-any-angle-paths for reference
local Heap = require ("core.heap")
local thetAStar = class("thetAStar")
local searchCenter = require("searchCenter"):shareInstance()

local abs = math.abs
local sqrt = math.sqrt
local sqrt2 = sqrt(2)

--- Euclidian distance with weight of railway.
function thetAStar:euclidian(nodeA, nodeB, aid)
    local dx = nodeA._x - nodeB._x
    local dy = nodeA._y - nodeB._y
    local g = sqrt(dx * dx + dy * dy)
    if searchCenter:isUsableRailway(nodeA._x, nodeA._y, aid) and searchCenter:isUsableRailway(nodeB._x, nodeB._y, aid) and (nodeA._x == nodeB._x or nodeA._y == nodeB._y) then
        g = g/10
    end
    return g
end

--- Euclidian distance.
function thetAStar:heuristic(nodeA, nodeB)
    local dx = nodeA._x - nodeB._x
    local dy = nodeA._y - nodeB._y
    return sqrt(dx * dx + dy * dy)
end

function thetAStar:lineOfSight(finder, node, neighbour, aid)
    local land1, land2 = finder._grid:getLand(node), finder._grid:getLand(neighbour)
    if land1 and land2 and (land1 == land2 or land2 == 0) then
        local usable1, usable2 = searchCenter:isUsableRailway(node._x, node._y, aid), searchCenter:isUsableRailway(neighbour._x, neighbour._y, aid)
        if usable1 == usable2 and (not usable1 or (node._x == neighbour._x or node._y == neighbour._y)) then
            if node._parent and (searchCenter:isUsableRailway(node._parent._x, node._parent._y, aid) ~= usable1 or not (node._parent._x == neighbour._x or node._parent._y == neighbour._y)) then
                return false
            end
            return true
        end
    end
    return false
end

-- Updates vertex node-neighbour
function thetAStar:updateVertex(finder, openList, node, neighbour, endNode, aid)
    local node2 = self:lineOfSight(finder, node, neighbour, aid) and node._parent or node
    local g = node2._g + self:euclidian(neighbour, node2, aid)
    if openList:isIn(neighbour) then
        if neighbour._g > g then
            neighbour._parent = node2
            neighbour._g = g
            neighbour._f = neighbour._g + neighbour._h
            openList:heapify(neighbour)
        end
    else
        neighbour._parent = node2
        neighbour._g = g
        neighbour._h = self:heuristic(neighbour, endNode)
        neighbour._f = neighbour._g + neighbour._h
        neighbour._opened = true
        openList:push(neighbour)
    end
end

-- Calculates a path.
-- Returns the path from location `<startX, startY>` to location `<endX, endY>`.
function thetAStar:getPath(finder, startNode, endNode, aid)
    local openList = Heap.new()
    startNode._g = 0
    startNode._h = self:heuristic(startNode, endNode)
    startNode._f = startNode._g + startNode._h
    startNode._opened = true
    openList:push(startNode)
    finder.toClear[startNode] = true

    local node = nil
    while not openList:empty() do
        node = openList:pop()
        node._closed = true
        if node == endNode then
            return node
        end
        local neighbours = finder._grid:getNeighbours(node)
        for i, neighbour in pairs(neighbours) do
            if not neighbour._closed then
                finder.toClear[neighbour] = true
                self:updateVertex(finder, openList, node, neighbour, endNode, aid)
            end
        end
    end
    return nil
end

return thetAStar