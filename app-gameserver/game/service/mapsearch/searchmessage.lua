local client_request =  require "client_request"
local config = require "config"
local clusterext = require "clusterext"
local mapcommon = require "mapcommon"
local mapUtils = require "mapUtils"

function client_request.sdfsd(player, msg)
	local ret = {}
	local code = global_code.unkown

	repeat
		if not msg.x or not msg.y or not msg.radius or msg.radius <= 0 then
			code = global_code.error_param
			break
		end
	until 0

	ret.code = code
	return ret
end