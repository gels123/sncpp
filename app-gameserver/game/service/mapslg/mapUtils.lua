local mapConf = require "mapConf"
local mapUtils = {}

function mapUtils.get_coord_id(x, y)
	return y * 10000 + x
end

function mapUtils.get_coord_xy(id)
	local y = math.floor(id / 10000)
	local x = id % 10000
	return x, y
end

--获取指定pos内九宫格所有坐标点, r半径
function mapUtils.get_around_pos(x, y, r)
	r = r or 1
	local pos = {}
	for iy=y+r,y-r,-1 do
		for ix=x-r,x+r do
			table.insert(pos, {ix, iy})
		end
	end
	return pos
end

--两点间距离
function mapUtils.distance(x1, y1, x2, y2)
	return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end

function mapUtils.chunckxy(x, y)
	return math.ceil(x/9), math.ceil(y/9)
end

--坐标转块ID
function mapUtils.get_chunck_id(x, y)
	return math.ceil(y/9) * 10000 + math.ceil(x/9)
end


return mapUtils