--[[
    谷歌翻译服务中心
]]
local skynet = require "skynet"
local httpc = require "http.httpc"
local cjson = require("cjson")
local googletoken = require "googletoken"
local googletranslate_lang = require "googletranslate_lang"
local linklist = require "linkList"
local luacurl = require("luacurl")
local googleTranslateConf = require("googleTranslateConf")
local pushMessageltCtrl = require("pushMessageltCtrl")
local md5 = require("md5")
-- local webclientlib = require 'webclient'
-- local webclient = webclientlib.create()
local serviceCenterBase = require "serviceCenterBase2"
local googleTranslateCenter = class("googleTranslateCenter", serviceCenterBase)

local client_header = {
	["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.73 Safari/537.36",
	["Accept-Encoding"] = "gzip, deflate, sdch",
	["Accept"] ="*/*",
}
local locallanguage = "en"
local sourcelanguage = "auto"
local listkey = "translate"
local MAX_REQ =  6 --max translation count, one translation has some request to google site

--[[translate
text->string, text to be translated
langs->table, like {"zh-CN","ar","af","sq","hy"}
delay response is something like:
{
   "sl"        = "en"
   "text"      = "hello world - 1"
   "translate" = {
       "af"    = "Hello World - 1"
       "ar"    = "مرحبا العالم - 1"
       "hy"    = "Բարեւ աշխարհ - 1"
       "sq"    = "Hello World - 1"
       "zh-CN" = "你好世界 - 1"
       }
}
]]

--[[
	切换为免费的
]]
function googleTranslateCenter:free()
	self:translate_switch(false)
	return true
end

--[[
	切换为收费的
]]
function googleTranslateCenter:fee()
	self:translate_switch(true)
	return true
end

function googleTranslateCenter:isServiceFee()
	return self.feeservice
end

function googleTranslateCenter:translate_switch(value)
	if type(value) == "boolean" then
		self.feeservice =  value
		if false == value then
			gLog.i("current translation type is free", self.feeservice)
		else
			gLog.i("current translation type is fee", self.feeservice)
		end
	end
end

--[[
	切换新旧
]]
function googleTranslateCenter:setTranslateVersion(isUseNew)
	if isUseNew then
		self.isUseNew = true
	else
		self.isUseNew = false
	end
end

--[[
	构造
]]
function googleTranslateCenter:ctor()
	-- print("googleTranslateCenter:ctor==")
	googleTranslateCenter.super.ctor(self)

	self.linklist = linklist.new(listkey)
	self.reqcoroutine = nil
	self.count = 0 -- current translating
	self.myclosure = {} -- clouse table
	self.mytranslation = {} -- cache my translationg
	self.myIndex = 0 -- index for closure key when the key is duplicate
	self.forkcount = 0 -- fork count,but never decrease
	self.feeservice =  false
	self.modeMaster = false --这似乎只是缓存开关，暂时关闭
	self.logTime = skynet.time()
	self.logInterval = 60 * 30--30分钟
	self.requestLogTime = skynet.time()
	self.requestLogInterval = 60 * 15--15分钟
	self.statistics = {["1"]=0,["1-2"]=0,["2-3"]=0,["3-4"]=0,["4-5"]=0,["5-6"]=0,["6"]=0,["allcount"] = 0 } --统计超时时间
	self.statisticsLogInterval = 60 * 12 --分钟
	self.statisticsLogTime = skynet.time()
	self.subIndex = 1
	self.curl = nil
	self.curlList = {}
	self.curlCurNum = 0
	self.curlMaxNum = 25
	self.isUseNew = true --是否使用新版本翻译
end

--[[
	初始化
]]
function googleTranslateCenter:init(kid)
    gLog.i("==========serverStartService googleTranslateCenter:init start==========")

	-- 初始化王国ID
	self.kid = tonumber(kid)

	pushMessageltCtrl:initialize()

    MAX_REQ = 16

	return true
end

--[[call by googletranslate_service master
]]
function googleTranslateCenter:initByMaster(subindex,kid)
    gLog.i("call by googletranslate_service master ==========serverStartService googleTranslateCenter:init start==========",subindex,kid)
    self.kid = kid
    --王国id
    self.kid = self.kid
    --sub index
    self.subIndex = subindex

	pushMessageltCtrl:initialize()

    self.modeMaster = false

    MAX_REQ = 2

    self.feeservice = false --默认使用免费翻译
end

--[[翻译时间统计记录
]]
function googleTranslateCenter:statisticsLogFunc(mTime)
  local tmpDeltaTime = skynet.time() - self.statisticsLogTime
  --统计超时时间
  self.statistics["allcount"] = self.statistics["allcount"] + 1
  local tmpTime = mTime
  if tmpTime <= 1 then
   self.statistics["1"] = self.statistics["1"] + 1
  elseif 1 < tmpTime  and 2 >= tmpTime then
   self.statistics["1-2"] = self.statistics["1-2"] + 1
  elseif 2 < tmpTime  and 3 >= tmpTime then
   self.statistics["2-3"] = self.statistics["2-3"] + 1
  elseif 3 < tmpTime  and 4 >= tmpTime then
   self.statistics["3-4"] = self.statistics["3-4"] + 1
  elseif 4 < tmpTime  and 5 >= tmpTime then
   self.statistics["4-5"] = self.statistics["4-5"] + 1
  elseif 5 < tmpTime  and 6 >= tmpTime then
   self.statistics["5-6"] = self.statistics["5-6"] + 1
  elseif 6 < tmpTime then
   self.statistics["6"] = self.statistics["6"] + 1
  end
  if tmpDeltaTime > self.statisticsLogInterval then --
      self.statisticsLogTime = skynet.time()
      for k,v in pairs(self.statistics) do
        if "allcount" ~= k then
          gLog.i(string.format("googletranslate center subIndex=%d [%s],count= %d ,%f --------",self.subIndex, k , self.statistics[k] , (self.statistics[k]/self.statistics["allcount"]) ))
        end
      end
  end
end

--[[记录请求的日志记录
mReason->string,记录文本
mErrorCode->number,状态位
]]
function googleTranslateCenter:requestLogFunc( mReason,mErrorCode )
	local tmpLogTime = skynet.time() - self.requestLogTime
	if tmpLogTime > self.requestLogInterval then
		self.requestLogTime = skynet.time()
		local tmpTimeStr = os.date("%Y-%m-%d %H:%M:%S", svrFunc.systemTime())
		gLog.i("requestLog,code=" .. tostring(mErrorCode).." ,[ " .. tmpTimeStr .. " ] :".. mReason)
	end
end

-- function googleTranslateCenter:newTranslate( text,langs )
-- 	--去掉左右空格
-- 	text = string.gsub(text, "^[ \t\n\r]+", "")
--     text = string.gsub(text, "[ \t\n\r]+$", "")

-- 	-- local closure  = skynet.response()
-- 	-- local ret = {}
-- 	-- ret.text = text
-- 	-- ret.translate = {}
-- 	-- ret.translatetime = {}
-- 	-- ret.time = skynet.time()
-- 	-- local items = nil
-- 	-- local xpcallok = nil
-- 	-- sq(function()
-- 		xpcallok,items = xpcall(handler(self,self.webclient_send_translate),svrFunc.exception,text,langs)
-- 	-- 	end)
-- 	-- xpcall(handler(self,self.webclient_multi_test),svrFunc.exception,text,langs)
	

-- 	-- for k,v in pairs(items) do 
-- 	-- 	ret.translate[v.tl] = v.translation
-- 	-- 	ret.translatetime[v.tl] = v.itemtime
-- 	-- 	if nil == ret.sl then --源语言
-- 	-- 		ret.sl = v.sl
-- 	-- 	end
-- 	-- end
-- 	-- ret.time = skynet.time() - ret.time
-- 	-- closure(true,ret)
-- 	--mytranslation作用相当于缓存
-- 	-- if true == self.modeMaster and nil == self.mytranslation[ret.text] then
-- 	-- 	self.mytranslation[ret.text] = {count=0,data=ret}
-- 	-- end
-- end

--[[
	翻译
]]
function googleTranslateCenter:translate(text, lang, isCN)
	local APPID =  pushMessageltCtrl:getPushAppID()
	local APPKEY = pushMessageltCtrl:getPushAppKey()
	if isCN then
		APPID =  pushMessageltCtrl:getCNPushAppID()
		APPKEY = pushMessageltCtrl:getCNPushAppKey()
	end

	local closure  = skynet.response()
	local startTime = skynet.time()
	-- xpcallok,item = xpcall(handler(self,self.curl_send_translate_free),svrFunc.exception,text,lang)
	-- xpcallok,item = xpcall(handler(self,self.httpc_multi_test),svrFunc.exception,text,lang)
	local translateMethod = self.httpc_send_translate_free
	local url = nil
	if self.isUseNew then
		gLog.d("use new translate")
		if self:isServiceFee() then
			url = string.format("/feeTranslate/%s",APPID)
			translateMethod = self.new_curl_send_translate_fee
		else
			url = string.format("/commonTranslate/%s",APPID)
			translateMethod = self.new_httpc_send_translate_common
		end 
	else
		gLog.d("use old translate")
		if self:isServiceFee() then
			translateMethod = self.curl_send_translate_fee
		else
			translateMethod = self.httpc_send_translate_free
		end
	end
	local xpcallok,item = xpcall(handler(self,translateMethod),svrFunc.exception,text,lang,url,isCN)
	
	if not xpcallok or not xpcallok  then
		-- print("xpcallok ======> false for text = " .. text)
	end
	if item then
		--如果翻译结果中没有原语则添加进翻译结果
		if not item.translate[item.sl] then
			item.translate[item.sl] = item.text
		end
		closure(true,item)
	else
		closure(true,nil)
	end
end

--[[
	批量翻译请求测试
	使用模拟返回数据，不会返回真正的http response信息
]]
function googleTranslateCenter:translateTest(text,lang,testIP,forkNum,superStartTime)
	local closure  = skynet.response()
	local startTime = skynet.time()
	local callMethod = nil
	-- testMethod = testMethod or "httpc_multi_test"
	-- if "httpc_multi_test"==testMethod then
	-- 	callMethod = self.httpc_multi_test
	-- end

	xpcallok,item = xpcall(handler(self,self.httpc_test),svrFunc.exception,text,lang,testIP,forkNum,superStartTime)
	
	
	if not xpcallok or not xpcallok  then
		-- print("xpcallok ======> false for text = " .. text)
	end
	if item then
		--如果翻译结果中没有原语则添加进翻译结果
		if not item.translate[item.sl] then
			item.translate[item.sl] = item.text
		end
		closure(true,item)
	else
		closure(true,nil)
	end
end

function googleTranslateCenter:request_translate( myitem )
	-- gLog.dump(myitem," myitem =====")
	-- local closure  = skynet.response()
	local text = myitem.text
	local lang = myitem.lang
	local closure = self.myclosure[myitem.key]
	-- print("translate closure 2=",closure," key=",myitem.key)
	local ret = {}
	ret.text = text
	ret.translate = {}
	ret.translatetime = {}
	ret.time = skynet.time()
	local continue_translate = true
	for i=1,#lang do
		local tl = lang[i]
		-- ret.translate[tl] = ""
		if nil ~= googletranslate_lang[tostring(tl)]  and true == continue_translate then
			local itemtime = skynet.time()
			local item = nil
			if true == self.modeMaster then 
				item = self:send_translate(text,tl)
			else
				item = self:send_translate_fee(text,tl)
			end

			if nil ~= item then
				ret.translate[tl] = item.translation
				ret.translatetime[tl] = skynet.time() - itemtime
				if nil == ret.sl then --源语言
					ret.sl = item.sl
				end
			else
				continue_translate = false
				gLog.i("item is nil when translate :",text)
			end
		end
	end
	ret.time = skynet.time() - ret.time
	self.count = self.count - 1
	-- print("request translate count = ",self.count)
	-- return ret
	-- gLog.dump(ret," my real ret=")

	if closure == nil then
		gLog.i("closure is nil key is====",myitem.key)
	end

	closure(true,ret)
	
	self.myclosure[myitem.key] = nil

	if true == self.modeMaster and nil == self.mytranslation[ret.text] then
		self.mytranslation[ret.text] = {count=0,data=ret}
	end

	-- print("request_translate count == ",self.count)
	-- if 0 < self.linklist:size() then
	-- 	skynet.wakeup(self.reqcoroutine)
	-- else
	-- 	-- gLog.dump(self.mytranslation," self.mytranslation=",5)
	-- end
end

function googleTranslateCenter:send_translate( text,target_lang )
	local tmporigintext = (text)
	-- text =  string.gsub(text, [[,]], [[，]])
	local url_locate = "/translate_a/single?client=t&sl="..sourcelanguage .."&tl=" .. target_lang .. "&hl=" .. locallanguage .. "&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&dt=at&ie=UTF-8&oe=UTF-8&source=btn&ssel=3&tsel=0&kc=0&tk=" .. googletoken.generate(text) .. "&q=" .. string.urlencode(text)
	-- print("url_locate=",url_locate)
    
	local respheader = {}
	local xpcallok, status, body = xpcall(httpc.get, svrFunc.exception, googleTranslateConf.google_translate_site, url_locate, respheader,client_header)
	-- local status, body = httpc.get(googleTranslateConf.google_translate_site, url_locate, respheader,client_header)
	-- print("status =====>", status)
	-- print(body)
	if  nil == xpcallok or false == xpcallok then
		return nil
	end

	if 200 ==  status then
		local zlib = require("zlib")
		local uncompress = zlib.inflate()
		local inflated, eof, bytes_in, bytes_out= uncompress(body)
		-- print("inflated ======",inflated)

	 -- 	inflated = string.gsub(inflated, "(,)(,)", [[%1""%2]])
	 --    inflated = string.gsub(inflated, "(,)(,)", [[%1""%2]])
		-- inflated = string.gsub(inflated, "(%[)(,)", [[%1""%2]])

		local size = #inflated
		local tb_pos = {}
		local record = true
		for i = 1, size do
		    local c = string.sub(inflated, i, i)
		    if [["]] == c then
		        local j = i - 1
		        if j >= 1 and string.sub(inflated, j, j) ~= [[\]] then
		            record = not record
		        end
		    elseif "," == c then
		        if record then
		            if i + 1 <= size and "," == string.sub(inflated, i + 1, i + 1) then
		                table.insert(tb_pos, i)
		            end
		        end
			elseif "[" == c then
		        if record then
		            local j = i + 1
		            if j <= size and "," == string.sub(inflated, j, j) then
		                table.insert(tb_pos, i)
		            end
		        end
		    end
		end

		local ret = ""
		local j = 1
		for i,v in ipairs(tb_pos) do
		    ret = ret .. string.sub(inflated, j, v) .. [[""]]
		    j = v + 1
		end
		ret = ret .. string.sub(inflated, j)
		inflated = ret
		local trans = cjson.decode(inflated)
		-- gLog.dump(trans," trans=",10)
		-- gLog.dump(ret," ret=",10)
		if nil ~= trans and nil ~=trans[1] and nil ~=trans[1][1] then
			local myorigintext = ""
			local mytranslation = ""
			local myoriginlanguage = ""
			for i=1,#(trans[1]) do
				if nil ~=trans[1][i][1] and nil ~=trans[1][i][2] and nil ~=trans[3] then
					local translate_text, origin_text = trans[1][i][1],trans[1][i][2]
					local origin_lang = trans[3]
					if origin_lang ==  target_lang then
						myorigintext = tmporigintext
					else
						myorigintext = myorigintext .. origin_text
					end
					if 0 == string.len(myoriginlanguage) then
						myoriginlanguage = origin_lang
					end
					
					mytranslation = mytranslation .. translate_text
				end
			end
			return {translation=mytranslation,text=myorigintext,sl=myoriginlanguage,tl=target_lang}
		end
		return nil
	end
	return nil
end

function googleTranslateCenter:curl_send_translate(text,target_lang)--test
	local tmporigintext = text
	-- text =  string.gsub(text, [[,]], [[，]])
	local url_locate = "/translate_a/single?client=t&sl="..sourcelanguage .."&tl=" .. target_lang .. "&hl=" .. locallanguage .. "&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&dt=at&ie=UTF-8&oe=UTF-8&source=btn&ssel=3&tsel=0&kc=0&tk=" .. googletoken.generate(text) .. "&q=" .. string.urlencode(text)
	-- print("url_locate=",url_locate)
	local httpurl ="http://" .. googleTranslateConf.google_translate_site .. url_locate
	-- print("httpurl = ",httpurl)
	local mywritedata = {}
	local mybuffer = ""
	local myRequestRet = "" --记录请求返回值
    local xpcallok
	local curlres
	local errmsg,errcode
	if self.curl == nil then
		self.curl = luacurl.easy()
	end

	self.curl:setopt(luacurl.OPT_USERAGENT,client_header["User-Agent"])
	self.curl:setopt(luacurl.OPT_URL,httpurl)
	self.curl:setopt(luacurl.OPT_NOSIGNAL,true)
	self.curl:setopt(luacurl.OPT_CONNECTTIMEOUT,3)
	self.curl:setopt(luacurl.OPT_TIMEOUT,3)
	local setretres = self.curl:setopt(luacurl.OPT_WRITEFUNCTION,function ( userparam, buffer )
		mybuffer = mybuffer .. buffer
		return string.len(buffer)
	end)
	self.curl:setopt(luacurl.OPT_WRITEDATA,mywritedata)
	xpcallok,curlres,errmsg,errcode = xpcall(handler(self.curl,self.curl.perform),svrFunc.exception)
	if  nil == xpcallok or false == xpcallok   then	
		self.curl:close()
		self.curl = nil
		self:requestLogFunc(" xpcall curl.perform failed ",1)
		return nil
	end
		
	if false == curlres then
		gLog.i("reconncet to curl ........")
		mybuffer= ""
		mywritedata = {}
	    myRequestRet = ""
		self.curl:close()
		self.curl = nil
		self.curl = luacurl.easy()
	   	self.curl:setopt(luacurl.OPT_USERAGENT,client_header["User-Agent"])
		self.curl:setopt(luacurl.OPT_URL,httpurl)
		self.curl:setopt(luacurl.OPT_NOSIGNAL,true)
		self.curl:setopt(luacurl.OPT_CONNECTTIMEOUT,3)
		self.curl:setopt(luacurl.OPT_TIMEOUT,3)
		local setretres = self.curl:setopt(luacurl.OPT_WRITEFUNCTION,function ( userparam, buffer )
			mybuffer = mybuffer .. buffer
			return string.len(buffer)
		end)
		self.curl:setopt(luacurl.OPT_WRITEDATA,mywritedata)
		xpcallok,curlres,errmsg,errcode = xpcall(handler(self.curl,self.curl.perform),svrFunc.exception)
		if  nil == xpcallok or false == xpcallok   then
			self.curl:close()
			self.curl = nil
			self:requestLogFunc(" xpcall curl.perform failed 2",1)
			return nil
		end
	end

	if true == curlres then
		-- print("mybuffer === ", mybuffer)
		myRequestRet = myRequestRet .. mybuffer

		local size = #mybuffer
		local tb_pos = {}
		local record = true
		for i = 1, size do
		    local c = string.sub(mybuffer, i, i)
		    if [["]] == c then
		        local j = i - 1
		        if j >= 1 and string.sub(mybuffer, j, j) ~= [[\]] then
		            record = not record
		        end
		    elseif "," == c then
		        if record then
		            local j = i + 1
		            if i + 1 <= size and "," == string.sub(mybuffer, i + 1, i + 1) then
		                table.insert(tb_pos, i)		          
		            end
		        end
		    elseif "[" == c then
		        if record then
		            local j = i + 1
		            if j <= size and "," == string.sub(mybuffer, j, j) then
		                table.insert(tb_pos, i)
		            end
		        end
		    end
		end

		local ret = ""
		local j = 1
		for i,v in ipairs(tb_pos) do
		    ret = ret .. string.sub(mybuffer, j, v) .. [[""]]
		    j = v + 1
		end
		ret = ret .. string.sub(mybuffer, j)
		mybuffer = ret

		local xpcallcjson, trans = xpcall(cjson.decode,svrFunc.exception,mybuffer)-- cjson.decode(mybuffer)
		if  nil == xpcallcjson or false == xpcallcjson   then
			local tmpRetString = " xpcall cjson.decode failed,buffer origin= " .. myRequestRet
			self:requestLogFunc(tmpRetString,1)
			-- print("error =======")
			return nil
		end
		-- gLog.dump(trans," trans=",10)
		-- gLog.dump(ret," ret=",10)
		if nil ~= trans and nil ~=trans[1] and nil ~=trans[1][1] then
			local myorigintext = ""
			local mytranslation = ""
			local myoriginlanguage = ""
			for i=1,#(trans[1]) do
				if nil ~=trans[1][i][1] and nil ~=trans[1][i][2] and nil ~=trans[3] then
					local translate_text, origin_text = trans[1][i][1],trans[1][i][2]
					local origin_lang = trans[3]
					if origin_lang ==  target_lang then
						myorigintext = tmporigintext
					else
						myorigintext = myorigintext .. origin_text
					end
					if 0 == string.len(myoriginlanguage) then
						myoriginlanguage = origin_lang
					end
					
					mytranslation = mytranslation .. translate_text
				end
			end
			return {translation=mytranslation,text=myorigintext,sl=myoriginlanguage,tl=target_lang}

		end

		self:requestLogFunc(" xpcall curl.perform result not fullfilled condition ",2)
		return nil
	end

	self:requestLogFunc(" xpcall curl.perform return failed ",3)
	return nil
end

--[[新通用的翻译,http请求
]]
function googleTranslateCenter:new_httpc_send_translate_common( text,target_lang,url,isCN)
	gLog.d("googleTranslateCenter:new_httpc_send_translate_common")

	local APPID =  pushMessageltCtrl:getPushAppID()
	local APPKEY = pushMessageltCtrl:getPushAppKey()
	
	if isCN then
		APPID =  pushMessageltCtrl:getCNPushAppID()
		APPKEY = pushMessageltCtrl:getCNPushAppKey()
	end
	
	local curtime = svrFunc.systemTime()
	local reqjson = string.format([==[{"appId":"%s","sl":"%s","st":"%s","timestamp":%d,"tl":"%s"}]==], APPID, target_lang, text, curtime,target_lang)
    gLog.d("new_httpc_send_translate_common reqjson===",reqjson)
    local sign = md5.sumhexa(reqjson..APPKEY)
    reqjson = string.format([==[{"appId":"%s","sl":"%s","st":"%s","timestamp":%d,"tl":"%s","sign":"%s"}]==], APPID, target_lang, text, curtime,target_lang,sign)
	gLog.d("new_httpc_send_translate_common===", url, reqjson)
	
	local ok, success, body = xpcall(svrFunc.httpPost, svrFunc.exception, googleTranslateConf.self_translate_site, reqjson, url, "application/json")
	gLog.d("new_httpc_send_translate_common: ok, success", ok, success)
	gLog.dump(body, "svrFunc.httpPost body",10)
	if not ok then
		return nil
	end

	if success then
		local transJson = cjson.decode(body)
		if transJson and transJson.rtncode == 0 then
			return {translate={[target_lang]=transJson.rspdata.tt[target_lang]},translatetime={[target_lang]=skynet.time()-curtime},text=text,sl=transJson.rspdata.sl}
		end		
	end
	return nil
end

--[[新收费的翻译,http请求
]]
function googleTranslateCenter:new_curl_send_translate_fee( text,target_lang,url,isCN)
	gLog.d("googleTranslateCenter:new_httpc_send_translate_fee")
	
	local APPID =  pushMessageltCtrl:getPushAppID()
	local APPKEY = pushMessageltCtrl:getPushAppKey()
	
	if isCN then
		APPID =  pushMessageltCtrl:getCNPushAppID()
		APPKEY = pushMessageltCtrl:getCNPushAppKey()
	end

    local curtime = svrFunc.systemTime()
	local reqjson = string.format([==[{"appId":"%s","sl":"%s","st":"%s","timestamp":%d,"tl":"%s"}]==], APPID, target_lang, text, curtime,target_lang)
    gLog.d("new_curl_send_translate_fee reqjson===",reqjson)
    local sign = md5.sumhexa(reqjson..APPKEY)
    reqjson = string.format([==[{"appId":"%s","sl":"%s","st":"%s","timestamp":%d,"tl":"%s","sign":"%s"}]==], APPID, target_lang, text, curtime,target_lang,sign)

	gLog.d("new_curl_send_translate_fee===", url, reqjson)
	local ok, success, body = xpcall(svrFunc.httpPost, svrFunc.exception, googleTranslateConf.self_translate_site, reqjson, url, "application/json")
	gLog.d("new_curl_send_translate_fee: ok, success", ok, success)
	gLog.dump(body, "svrFunc.httpPost body",10)
	if not ok then
		return nil
	end

	if success then
		local transJson = cjson.decode(body)
		if transJson and transJson.rtncode == 0 then
			return {translate={[target_lang]=transJson.rspdata.tt[target_lang]},translatetime={[target_lang]=skynet.time()-curtime},text=text,sl=transJson.rspdata.sl}
		end		
	end
	return nil
end

--[[收费的翻译,curl请求
]]
function googleTranslateCenter:curl_send_translate_fee( text,target_lang )
	-- print("googleTranslateCenter:curl_send_translate_fee text:",text,",target_lang:",target_lang)
	local startTime = skynet.time()
	local url_locate = "/language/translate/v2?key="..googleTranslateConf.YOUR_API_KEY .."&target=" .. target_lang .. "&q=" .. string.urlencode(text)
	-- print("fee  ===>url_locate=",url_locate)
    local httpurl ="https://" .. googleTranslateConf.google_translate_fee_site .. url_locate
	-- print("httpurl = ",httpurl)
	local mywritedata = {}
	local mybuffer = ""
    local curl = luacurl.easy()
    -- print("client_header=",client_header["User-Agent"])
	curl:setopt(luacurl.OPT_USERAGENT,client_header["User-Agent"])
	-- curl:setopt(luacurl.OPT_ENCODING,client_header["Accept-Encoding"])
	curl:setopt(luacurl.OPT_URL,httpurl)
	curl:setopt(luacurl.OPT_SSL_VERIFYPEER,false) --https
	curl:setopt(luacurl.OPT_SSL_VERIFYHOST,0) --https
	curl:setopt(luacurl.OPT_NOSIGNAL,true)
	-- curl:setopt(luacurl.OPT_VERBOSE,true) --for debug info
	--curl:setopt(luacurl.OPT_DNS_USE_GLOBAL_CACHE,true)
	curl:setopt(luacurl.OPT_CONNECTTIMEOUT,3)
	curl:setopt(luacurl.OPT_TIMEOUT,3)

	local setretres = curl:setopt(luacurl.OPT_WRITEFUNCTION,function ( userparam, buffer )
		-- gLog.dump(userparam,"userparam = ")
		-- print("buffer = ",buffer)
		mybuffer = mybuffer .. buffer
		-- print("buffer = ",mybuffer)
		return string.len(buffer)
	end)
	curl:setopt(luacurl.OPT_WRITEDATA,mywritedata)
	local xpcallok,curlres,errmsg,errcode = xpcall(handler(curl,curl.perform),svrFunc.exception)

	curl:close()
	curl = nil

	if  nil == xpcallok or false == xpcallok   then
		return nil
	end

	--[[
		200 OK

		{
		    "data": {
		        "translations": [
		            {
		                "translatedText": "Hallo Welt",
		                "detectedSourceLanguage": "en"
		            }
		        ]
		    }
		}
	]]

	-- print("status == ",curlres)
	if true ==  curlres then
		--预防cjson.decode报错
		local xpcallcjson, bodydecode = xpcall(cjson.decode,svrFunc.exception,mybuffer)
		if  nil == xpcallcjson or false == xpcallcjson   then
			local tmpRetString = "curl_send_translate_fee xpcall cjson.decode failed,buffer origin= " .. mybuffer
			self:requestLogFunc(tmpRetString,1)
			return nil
		end

		if nil == bodydecode then
			return nil
		end
		if nil == bodydecode.data then
			return nil
		end
		local translate_text, origin_text = bodydecode.data.translations[1].translatedText,text
		-- print("paid translation =" ,translate_text, origin_text)
		local origin_lang = bodydecode.data.translations[1].detectedSourceLanguage
		-- print("paid translation origin_lang=" ,origin_lang)
		-- return {translation=translate_text,text=origin_text,sl=origin_lang,tl=target_lang}
		return {translate={[target_lang]=translate_text},translatetime={[target_lang]=skynet.time()-startTime},text=origin_text,sl=origin_lang}
	end
	return nil
end





--[[免费的翻译,curl请求
]]
function googleTranslateCenter:curl_send_translate_free( text,target_lang )
	local startTime = skynet.time()
	--去掉左右空格
	text = string.gsub(text, "^[ \t\n\r]+", "")
    text = string.gsub(text, "[ \t\n\r]+$", "")
	local url_locate = "/transerver/tran?tl=" .. target_lang .. "&st=" .. string.urlencode(text)
    local httpurl ="http://" .. googleTranslateConf.self_translate_site .. url_locate
    -- local httpurl  = "http://127.0.0.1:9001"
	local mywritedata = {}
	local mybuffer = ""
    
    if self.curl == nil then
		self.curl = luacurl.easy()
	end
    -- print("client_header=",client_header["User-Agent"])
	self.curl:setopt(luacurl.OPT_USERAGENT,client_header["User-Agent"])
	-- curl:setopt(luacurl.OPT_ENCODING,client_header["Accept-Encoding"])
	self.curl:setopt(luacurl.OPT_URL,httpurl)
	-- curl:setopt(luacurl.OPT_SSL_VERIFYPEER,false) --https
	-- curl:setopt(luacurl.OPT_SSL_VERIFYHOST,0) --https
	self.curl:setopt(luacurl.OPT_NOSIGNAL,true)
	-- curl:setopt(luacurl.OPT_VERBOSE,true) --for debug info
	--curl:setopt(luacurl.OPT_DNS_USE_GLOBAL_CACHE,true)
	self.curl:setopt(luacurl.OPT_CONNECTTIMEOUT,3)
	self.curl:setopt(luacurl.OPT_TIMEOUT,3)

	local setretres = self.curl:setopt(luacurl.OPT_WRITEFUNCTION,function ( userparam, buffer )
		-- gLog.dump(userparam,"userparam = ")
		-- print("buffer = ",buffer)
		mybuffer = mybuffer .. buffer
		-- print("buffer = ",mybuffer)
		return string.len(buffer)
	end)
	self.curl:setopt(luacurl.OPT_WRITEDATA,mywritedata)
	local xpcallok,curlres,errmsg,errcode = xpcall(handler(self.curl,self.curl.perform),svrFunc.exception)
	-- curl:close()
	if  nil == xpcallok or false == xpcallok   then	
		self.curl:close()
		self.curl = nil
		self:requestLogFunc(" xpcall curl.perform failed ",1)
		return nil
	end
	if true ==  curlres then
		-- print("curl_send_translate_free real ret=" , mybuffer)
		local transJson = cjson.decode(mybuffer)
		-- local transJson = {rspdata={tt={[target_lang] = "webclient test"},sl="zh-CN"},rtncode="SUCCESS"}
		if transJson and transJson.rtncode == "SUCCESS" then
			return {translate={[target_lang]=transJson.rspdata.tt[target_lang]},translatetime={[target_lang]=skynet.time()-startTime},text=text,sl=transJson.rspdata.sl}
		end
	end
	return nil
end
--[[
	httpc的方式进行http请求
]]
function googleTranslateCenter:httpc_send_translate_free( text,target_lang )
	-- print("googleTranslateCenter:httpc_send_translate_free text:",text,",target_lang:",target_lang)
	local startTime = skynet.time()
	target_lang = tostring(target_lang)
	local url_locate = "/tran/?tl=" .. target_lang .. "&st=" .. string.urlencode(text)
	local content = ""
    
	local recvheader = {}
	local header = {}
	local xpcallok, status, body = xpcall(httpc.request, svrFunc.exception, "GET", googleTranslateConf.self_translate_site, url_locate, recvheader, header, content)
	if  nil == xpcallok or false == xpcallok then
		return nil
	end
	if 200 ==  status then
	-- if false then --模拟翻译失败情况
		local transJson = cjson.decode(body)
		if transJson and transJson.rtncode == "SUCCESS" then
			return {translate={[target_lang]=transJson.rspdata.tt[target_lang]},translatetime={[target_lang]=skynet.time()-startTime},text=text,sl=transJson.rspdata.sl}
		end		
	else 
		-- print("googleTranslateCenter:httpc_send_translate_free error",xpcallok, status, body)
	end
	return nil
end

--[[
	httpc的方式进行并发测试
]]
function googleTranslateCenter:httpc_test( text,target_lang,testIP,forkNum,superStartTime )
	local startTime = skynet.time()
	target_lang = tostring(target_lang)
	local host = testIP or googleTranslateConf.self_translate_site
	local url_locate = ""
	local content = ""
	forkNum = forkNum or ""
	-- local content = "{\"cmd\":1,\"subcmd\":108,\"data\":{\"auto\":1,\"kid\":1},\"sign\":\"7bdddaedb4c4c194371cf4dcb48e034b\",\"time\":14554558413}"
	if superStartTime then
		gLog.i("httpc_multi_test start [",text.."|"..target_lang,"],useTime:",skynet.time()-superStartTime)
	end
	local recvheader = {}
	local header = {}
	local xpcallok, status, body = xpcall(httpc.request, svrFunc.exception, "GET", host, url_locate, recvheader, header, content)
	-- print("httpc_multi_test return host:",host,",forkNum:",forkNum)
	if  nil == xpcallok or false == xpcallok then
		return nil
	end
	-- if 200 ==  status then
	gLog.i("httpc_multi_test ret useTime:",skynet.time()-superStartTime,",real ret=" , body)
	return {translate={[target_lang]="translateTest"..forkNum},translatetime={[target_lang]=skynet.time()-startTime},text=text,sl="zh-CN"}
	-- else 
	-- 	print("googleTranslateCenter:httpc_multi_test error",xpcallok, status, body)
	-- end
	-- return nil
end

return googleTranslateCenter
