--[[
	es搜索服务配置
]]
local elasticSearchConf = {}

if dbconf.DEBUG then -- 测试服
	elasticSearchConf.host = "127.0.0.1:9200"
	elasticSearchConf.user = "root"
	elasticSearchConf.password = "1"
else -- 正式服
	elasticSearchConf.host = "127.0.0.1:9200"
	elasticSearchConf.user = "root"
	elasticSearchConf.password = "1"
end

return elasticSearchConf