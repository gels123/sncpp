--[[
    谷歌翻译服务
]]
require "quickframework.init"
require "svrFunc"
require "configrequire"
require "sharedataLib"
local skynet = require "skynet"
local profile = require "skynet.profile"
local googleTranslateCenter = require("googleTranslateCenter"):shareInstance()

local mode, kid, instance = ...
kid, instance = tonumber(kid), tonumber(instance)
assert(kid and instance)

if mode == "master" then
    local mapCachedTranslation = {} --缓存内容，缓存文本:缓存翻译 ，{1={{"en","hello"},{"zh-cn","你好"}},2={}}
    local intMaxCacheKey = 1000 --最大缓存编号，缓存容量，默认存储1000条
    local intCurCacheKey = 1 --目前缓存编号
    local mapTranslateQueue = {} --正在翻译队列，{{"text|lang"={finalclosure1,finalclosure2...}},{...}}
    local translatingTimeout = 5 --秒，正在翻译队列超时时间，如果一个队列翻译超时，则再次尝试翻译(暂时不用)

    local cached_used = true --缓存开关，默认开启
    local auto_translate = true --自动翻译功能开关

    local agent = {}

    local balance = 1

    --1秒内,1-2秒,2-3秒 ...
    local statistics = {["1"]=0,["1-2"]=0,["2-3"]=0,["3-4"]=0,["4-5"]=0,["5-6"]=0,["6"]=0,["allcount"] = 0 } --统计超时时间
    local statisticsStartTime = skynet.time()
    local statisticsLogInterval = 30*60 --秒

    skynet.start(function()
        gLog.i("googleTranslateCenter main starting")
        local ti = {}
        local myclosure = {} -- clouse table
        --启动多个代理服务
        instance = instance or 10
        for i = 1, instance, 1 do
            agent[i] = skynet.newservice(SERVICE_NAME, "sub", kid, i)
        end

        local function statisticsLogFunc(mTime)
            local tmpDeltaTime = skynet.time() - statisticsStartTime
            --统计超时时间
            statistics["allcount"] = statistics["allcount"] + 1
            local tmpTime = mTime
            if tmpTime <= 1 then
                statistics["1"] = statistics["1"] + 1
            elseif 1 < tmpTime  and 2 >= tmpTime then
                statistics["1-2"] = statistics["1-2"] + 1
            elseif 2 < tmpTime  and 3 >= tmpTime then
                statistics["2-3"] = statistics["2-3"] + 1
            elseif 3 < tmpTime  and 4 >= tmpTime then
                statistics["3-4"] = statistics["3-4"] + 1
            elseif 4 < tmpTime  and 5 >= tmpTime then
                statistics["4-5"] = statistics["4-5"] + 1
            elseif 5 < tmpTime  and 6 >= tmpTime then
                statistics["5-6"] = statistics["5-6"] + 1
            elseif 6 < tmpTime then
                statistics["6"] = statistics["6"] + 1
            end
            if tmpDeltaTime > statisticsLogInterval then --
                statisticsStartTime = skynet.time()
                for k,v in pairs(statistics) do
                    if "allcount" ~= k then
                        gLog.i(string.format("googletranslate service [%s],count= %d ,%f --------",k , statistics[k] , (statistics[k]/statistics["allcount"])))
                    end
                end
            end
        end

        --根据文本获取缓存索引
        local function getCacheKey(text)
            if not text or #text==0 then
                return
            end
            for i,translate in pairs(mapCachedTranslation) do
                for tolang,tranText in pairs(translate) do
                    if text == tranText then
                        return i,tolang
                    end
                end
            end
        end
        --添加翻译缓存
        local function addTranslationCache(transData,cacheKey)
            --事先已经有该语句的翻译缓存，则增添内容，无缓存则创建新缓存
            if not transData or not transData.translate then
                return
            end
            --检查一下是否已有翻译缓存，以防一个文本保存多份缓存
            cacheKey = cacheKey or getCacheKey(transData.text)
            if cacheKey then
            for tolang,tranText in pairs(transData.translate) do
                mapCachedTranslation[cacheKey][tolang] = tranText
            end
            else
            if intCurCacheKey>intMaxCacheKey then
                intCurCacheKey = 1
            end
            --mapCachedTranslation存储格式为{1={{"en","hello"},{"zh-cn","你好"}},2={}}
            mapCachedTranslation[intCurCacheKey] = transData.translate
            intCurCacheKey = intCurCacheKey+1
            end
        end

        --获取翻译缓存，可匹配原文以及所有翻译内容
        local function getTranslationCache(text,lang)
            if not text or #text==0 then
              return
            end
            local cacheKey,sl = getCacheKey(text)
            if cacheKey then
              local retData = {}
              if lang then
                if mapCachedTranslation[cacheKey][lang] then
                    retData.translate = {}
                    retData.translate[lang]=mapCachedTranslation[cacheKey][lang]
                  else
                    return nil,i
                  end
              else
                retData.translate = mapCachedTranslation[cacheKey]
              end
              retData.sl = sl
              retData.text = text
              return retData,i
            end

            -- for i,translate in pairs(mapCachedTranslation) do
            --   for tolang,tranText in pairs(translate) do
            --     -- print("getTranslationCache text=",text,",tranText=",tranText)
            --     if text == tranText then
            --       local retData = {}
            --       --如果指定了翻译语言，则只返回该语言的翻译内容
            --       if lang then
            --         -- gLog.dump(translate,"getTranslationCache translate",6)
            --         -- print("getTranslationCache lang=",lang,",translate[lang]=",translate[lang])
            --         if translate[lang] then
            --           retData.translate = {}
            --           retData.translate[lang]=translate[lang]
            --         else
            --           return nil,i
            --         end
            --       else
            --         retData.translate = translate
            --       end
            --       retData.sl = tolang
            --       retData.text = text
            --       dump(retData,"getTranslationCache retData",6)
            --       -- print("getTranslationCache retkey = ",i)
            --       return retData,i
            --     end
            --   end
            -- end
        end

        skynet.dispatch("lua", function(session, source, command, ...)
            profile.start()
            local subCommand = "translate"
            if "singleTest" == command or "multiTest" == command then
              subCommand = "translateTest"
            end


            if "init" == command then
              googleTranslateCenter:dispatchCmd(session, source, command, ...)
              for i= 1, instance do
                  skynet.send(agent[i],"lua","initByMaster",i,...)
              end
            elseif "close_cached" == command then
              cached_used = false
              skynet.ret(skynet.pack(true))
              gLog.i("translation do not use cached")
            elseif "open_cached" == command then
              cached_used = true
              skynet.ret(skynet.pack(true))
              gLog.i("translation use cached")
            elseif "switchAutoTranslate" == command then
              local data = ...
              gLog.i("googletranslate_service switchAutoTranslate data = ",data)
              if 1==data then
                auto_translate = true
                gLog.i("auto translation turnOn")
              else
                auto_translate = false
                gLog.i("auto translation turnOff")
              end
              skynet.ret(skynet.pack(true))
            elseif "translate" == command or "translateSingle" == command or "singleTest" == command then
              --lwk 20170323 添加，只进行单条翻译并单条返回，目前未加入日志打印和时间统计
              if "translateSingle" == command and not auto_translate then
                skynet.ret(skynet.pack(false,"locking"))
              else
                -- skynet.sleep(1000)
                local text,language,isCN,testIP,startTime = ...
                local queueKey = text.."|"..language
                local retData = nil
                local cacheData = nil
                local cacheKey = nil
                local beginTime = skynet.time()
                local finalclosure = skynet.response()
                --创建翻译队列
                mapTranslateQueue[queueKey] = mapTranslateQueue[queueKey] or {}
                mapTranslateQueue[queueKey].closureList = mapTranslateQueue[queueKey].closureList or {}
                --把回调函数放入队列
                table.insert(mapTranslateQueue[queueKey].closureList,finalclosure)
                --判断该文本和语言是否正在翻译，如果正在翻译则插入回调队列，待翻译结束后通过回调进行翻译结果返回
                if not mapTranslateQueue[queueKey].stratTime then --or skynet.time() - mapTranslateQueue[queueKey].stratTime > translatingTimeout then
                  --如果队列前边没人正在翻译，则开始进行翻译并且设定开始时间
                  mapTranslateQueue[queueKey].stratTime = skynet.time()
                  --为避免skynet.call超时阻塞，使用协程提交翻译请求
                  local function frokFunc()
                    --缓存判断
                    local is_cached = false
                    if cached_used and text then
                        cacheData,cacheKey = getTranslationCache(text,language)
                        if cacheData then
                          is_cached=true
                          retData = cacheData
                        end
                    end
                    --缓存中找不到则进行单条翻译
                    if not is_cached then
                      -- print("run translate queueKey=",queueKey,",cacheKey=",cacheKey)
                      -- gLog.dump(mapCachedTranslation,"mapCachedTranslation",8)
                      balance = balance + 1
                      if balance > #agent - 1 then balance = 1 end
                      local svraddres = agent[balance]
                      local ret = skynet.call(svraddres,"lua",subCommand,text,language,isCN,testIP,nil,startTime)
                      if ret then
                        retData = ret
                        --插入缓存
                        if cached_used and nil ~= ret.text then
                          addTranslationCache(ret,cacheKey)
                        end
                      else
                        --翻译失败
                        retData = {}
                      end
                    end
                    --获取翻译结果后对队列进行循环返回
                    local finalclosureQueue = mapTranslateQueue[queueKey].closureList
                    mapTranslateQueue[queueKey] = nil
                    if finalclosureQueue and #finalclosureQueue>0 then
                      for i,otherFinalclosure in pairs(finalclosureQueue) do
                        if 1 ~= i then
                          --只让其中一个线程进行译文存储
                          retData.saved = true
                        end
                        retData.time = skynet.time() - beginTime
                        otherFinalclosure(true,retData)
                      end
                    end
                  end
                  skynet.fork(frokFunc)
                end
              end
            elseif "translateMulti" == command or "multiTest" == command then
              if "translateMulti" == command and not auto_translate then
                skynet.ret()
              else
                local text,languages,testIP,startTime = ...
                local finalclosure = skynet.response()
                --缓存判断
                local cacheData = nil
                local cacheKey = nil
                local is_cached = false
                if true == cached_used and nil ~= text then
                  local cacheData,cacheKey = getTranslationCache(text)
                  if cacheData then
                    is_cached = true
                    finalclosure(true,cacheData)
                  end
                end
                if not is_cached and type(languages) ==  "table" then
                  local finalret = {}
                  finalret.translate = {}
                  finalret.translatetime = {}
                  finalret.time = skynet.time()
                  finalret.text = text
                  local langcount = #languages
                  local translatecount = 0
                  local forkNum = 0
                  for i=1,langcount do
                    --调用
                    local lang = languages[i]
                    local function fork_call( )
                        balance = balance + 1
                        if balance > #agent - 1 then balance = 1 end
                        local svraddres = agent[balance]
                        forkNum = forkNum + 1
                        local ret = skynet.call(svraddres,"lua",subCommand,text,lang,testIP,forkNum,startTime)
                        translatecount = translatecount + 1
                        if nil ~= ret then
                          if nil == finalret.sl and nil ~= ret.sl then
                            finalret.sl = ret.sl
                          end
                          finalret.translate[lang] = ret.translate[lang]
                          finalret.translatetime[lang] = ret.translatetime[lang]
                          if translatecount >= langcount then
                             finalret.time = skynet.time() - finalret.time
                             -- gLog.dump(finalret,"google service finalret",8)
                             finalclosure(true,finalret)
                             --插入缓存
                             if true == cached_used and nil ~= ret.text then
                                addTranslationCache(finalret,cacheKey)
                             end
                             --统计超时时间
                             statisticsLogFunc(finalret.time)
                          end
                        else
                          if translatecount >= langcount then
                            finalclosure(true,finalret)
                          end
                        end
                    end
                    skynet.fork(fork_call)
                  end
                end
              end
            -- elseif "newTranslate" == command then
            --   --新翻译插件测试(不在正式环境使用)
            --   local text,languages = ...
            --   balance = balance + 1
            --   if balance > #agent - 1 then balance = 1 end
            --   local svraddres = agent[balance]
            --   local ret = skynet.call(svraddres,"lua",command,text,languages)
            --   -- gLog.dump(ret,"newTranslate ret",8)
            --   local finalclosure = skynet.response()
            --   finalclosure(true,ret)
            --   statisticsLogFunc(ret.time)
            elseif "free" == command or "fee" == command then --其它指令(free,fee 两条指令切换)
                local count = 0
                for i= 1, instance do
                    local svraddres = agent[i]
                    local callret = skynet.call(svraddres,"lua",command,...)
                    if true == callret then
                      count =  count + 1
                    end
                    -- print("call address = ",svraddres," ret=",callret,"  count=",count," instance count=",instance)
                end
                if count == tonumber(instance) then
                  skynet.ret(skynet.pack(true))
                  print("switch success,now is =",command)
                else
                  skynet.ret(skynet.pack(false))
                  print("switch failed ")
                end
            elseif "setTranslateVersion" == command then
                gLog.d("setTranslateVersion======")
                local count = 0
                for i= 1, instance do
                    local svraddres = agent[i]
                    local callret = skynet.call(svraddres,"lua",command,...)
                    if true == callret then
                      count =  count + 1
                    end
                   -- print("call address = ",svraddres," ret=",callret,"  count=",count," instance count=",instance)
                end
                if count == tonumber(instance) then
                  skynet.ret(skynet.pack(true))
                  print("switch success,now is =",command)
                else
                  skynet.ret(skynet.pack(false))
                  print("switch failed ")
                end
            else
                googleTranslateCenter:dispatchCmd(session, source, command, ...)
            end

            --------
            local time = profile.stop()
            -- if time > gConstValue.OPT_TIME_OUT then
            if time > 5 then
                local p = ti[command]
                if p == nil then
                    p = { n = 0, ti = 0 }
                    ti[command] = p
                end
                p.n = p.n + 1
                p.ti = p.ti + time
            end
        end)

        -- 注册 info 函数, 便于debug指令 INFO 查询
        skynet.info_func(function()
            gLog.i("googleTranslateCenter ti=", table2string(ti))
            return ti
        end)

        local address = skynet.self()
        svrAddrMgr.setSvr(address,svrAddrMgr.googletranslateSvr,kid)
        skynet.call(address, "lua", "init",kid)

        --通知启动服务，本服务已经初始化完成
        local startSvr = svrAddrMgr.getSvr(svrAddrMgr.startSvr,kid)
        skynet.send(startSvr, "lua", "finishInit", "googleTranslateCenter")

        gLog.i("google translate main service finish ------------")
    end)

elseif mode == "sub" then
    local ti = {}

    skynet.start(function()

      skynet.dispatch("lua", function(session, source, command, ...)
          -- print("sub command ===",command)
          profile.start()
          googleTranslateCenter:dispatchCmd(session, source, command, ...)


          local time = profile.stop()
          -- if time > gConstValue.OPT_TIME_OUT then
          if time > 5 then
              local p = ti[command]
              if p == nil then
                  p = { n = 0, ti = 0 }
                  ti[command] = p
              end
              p.n = p.n + 1
              p.ti = p.ti + time
            end
      end)

       -- 注册 info 函数，便于 debug 指令 INFO 查询。
      skynet.info_func(function()
          -- gLog.dump(ti, "ti=", 10)
          return ti
      end)
    end)

    -- 设置本服务地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.googleTranslateSvr, kid)

    -- 初始化
    skynet.call(skynet.self(), "lua", "init", kid)
end