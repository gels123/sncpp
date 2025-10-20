--[[
	es搜索服务中心
]]
local skynet = require "skynet"
local crypt = require "skynet.crypt"
local netpack = require "skynet.netpack"
local httpc = require ("http.httpc")
local urllib = require ("http.url")
local luacurl = require ("luacurl")
local json = require ("json")
local serviceCenterBase = require("serviceCenterBase")
local elasticSearchCenter = class("elasticSearchCenter", serviceCenterBase)

local client_header = {
  ["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.73 Safari/537.36",
  ["Content-Type"] = "application/json; charset=UTF-8",
  -- ["content-type"] = "application/x-www-form-urlencoded",
  ["Accept"] ="*/*",
}

-- 构造
function elasticSearchCenter:ctor()
	-- 初始化
	self:init()
end

-- 初始化
function elasticSearchCenter:init()
	gLog.i("== elasticSearchCenter:init begin ==")
	--
	local elasticSearchConf = require ("elasticSearchConf")
	self.host = elasticSearchConf.host
	assert(self.host ~= nil, "elasticSearchCenter:init error: no host!")
	self.user = elasticSearchConf.user
	self.password = elasticSearchConf.password

	--
	if self.user and self.password then
	    client_header["Authorization"] = string.format("Basic %s", crypt.base64encode(self.user..":"..self.password))
	end

	gLog.i("== elasticSearchCenter:init end ==")
end


local curl

-- http请求
function elasticSearchCenter:httpc(_index, _type, _idOrOperate, _content, _reqCustomer)
	local url_locate
	if _index and _type and _idOrOperate then
		url_locate = string.format("/%s/%s/%s", tostring(_index), tostring(_type), tostring(_idOrOperate))
	elseif _index and _type then
		url_locate = string.format("/%s/%s", tostring(_index), tostring(_type))
	elseif _index and _idOrOperate then
		url_locate = string.format("/%s/%s", tostring(_index), tostring(_idOrOperate))
	elseif _index then
		url_locate = string.format("/%s", tostring(_index))
	end
	if _content then
		_content = json.encode(_content)
	end
	local recvheader = {}
	local xpcallOk, status, body = xpcall(httpc.request, svrFunc.exception, _reqCustomer, self.host, url_locate, recvheader, client_header, _content)
	gLog.i("elasticSearchCenter:httpc request=", self.host, url_locate , _reqCustomer, _content, "xpcallOk=", xpcallOk, status, body)
	if not xpcallOk then
		return nil
	end
	local ret = json.decode(body)
	if 200 == status or 201 == status then
		gLog.dump(ret, "elasticSearchCenter:httpc ret=", 10)
		return 0, ret
	end
	return status, ret
end

-- 
function elasticSearchCenter:perform(_index, _type, _idOrOperate, _content,_reqCustomer)
	if not curl then
		curl = luacurl.easy()
	end
	local mywritedata = {}
	local mybuffer = ""
	local xpcallOk,curlres,errmsg,errcode
	local url_locate = nil

	if _index and _type and _idOrOperate then
		url_locate = string.format("%s/%s/%s/%s", self.host, tostring(_index), tostring(_type),tostring(_idOrOperate))
	elseif _index and _type then
		url_locate = string.format("%s/%s/%s", self.host, tostring(_index), tostring(_type))
	elseif _index and _idOrOperate then
		url_locate = string.format("%s/%s/%s", self.host, tostring(_index), tostring(_idOrOperate))
	elseif _index then
		url_locate = string.format("%s/%s", self.host, tostring(_index))
	end
	if _content then
		_content = json.encode(_content)
		curl:setopt(luacurl.OPT_POSTFIELDS, _content)
	end
	-- print("url locate = ",url_locate)
	curl:setopt(luacurl.OPT_VERBOSE, true)
	curl:setopt(luacurl.OPT_USERAGENT, client_header["User-Agent"])
	curl:setopt(luacurl.OPT_HTTPHEADER, client_header["Content-Type"])
	curl:setopt(luacurl.OPT_URL, url_locate)  
	curl:setopt(luacurl.OPT_NOSIGNAL, true)
	curl:setopt(luacurl.OPT_CONNECTTIMEOUT, 3)
	curl:setopt(luacurl.OPT_TIMEOUT, 3)
	-- print("url self.user : self.password = ",self.user .. ":" .. self.password)
	if self.user and self.password then
		curl:setopt(luacurl.OPT_HTTPAUTH, 1)
		curl:setopt(luacurl.OPT_USERPWD, self.user .. ":" .. self.password)
	end
	if _reqCustomer then
		curl:setopt(luacurl.OPT_CUSTOMREQUEST,_reqCustomer)
	end
	-- curl:setopt(luacurl.OPT_VERBOSE,true)
	local setretres = curl:setopt(luacurl.OPT_WRITEFUNCTION, function(userparam, buffer)
		mybuffer = mybuffer .. buffer
		return string.len(buffer)
	end)
	curl:setopt(luacurl.OPT_WRITEDATA, mywritedata)

	xpcallOk,curlres,errmsg,errcode = xpcall(handler(curl, curl.perform), svrFunc.exception)
	if not xpcallOk then
		curl:close()
		curl = nil
		print(" xpcall curl.perform failed ",1)
		return nil
	end
	local ret = json.decode(mybuffer)
	if curlres then
		gLog.dump(ret,"elasticSearchCenter:perform ret =",10)
		return 0, ret
	end
	print("perform =",xpcallOk,curlres,errmsg,errcode)
	return errcode,ret
end

-- 设置
function elasticSearchCenter:set(_index, _type, _id, _content)
	return self:httpc(_index, _type, _id, _content, "POST")
end

-- 获取
function elasticSearchCenter:get(_index, _type, _id)    
	return self:httpc(_index, _type, _id, nil, "GET")
end

-- 查询
function elasticSearchCenter:search(_index, _type, _searchParam)    
	return self:httpc(_index, _type, "_search", _searchParam)
end

-- 删除
function elasticSearchCenter:delete(_index, _type, _id)
	return self:httpc(_index, _type, _id, nil, "DELETE")
end

-- 是否存在
function elasticSearchCenter:exist(_index, _type, _id)
	return self:httpc(_index, _type, _id, nil, "HEAD")
end

function elasticSearchCenter:mget(_index, _type, _mgetParam)
    return self:httpc(_index, _type, "_mget", _mgetParam)
end

function elasticSearchCenter:reindex(_reindexParam)
    return self:httpc(nil, nil, "_reindex", _reindexParam)
end

return elasticSearchCenter