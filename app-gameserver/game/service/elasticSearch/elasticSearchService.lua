--[[
	es搜索服务
    安装:
    https://es.xiaoleilu.com/010_Intro/00_README.html
    elasticsearch.yml下新增
    http.cors.enabled: true 
    http.cors.allow-origin: '*'
    http.cors.allow-headers: "Authorization"

    模糊搜索
    https://www.elastic.co/blog/found-fuzzy-search
    documents api
    https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html

    中文分词(IK+pinyin)
    https://www.cnblogs.com/xing901022/p/5910139.html

    bin/elasticsearch-plugin install discovery-multicast
    bin/elasticsearch-plugin install analysis-icu
    bin/elasticsearch-plugin install analysis-kuromoji
    bin/elasticsearch-plugin install analysis-phonetic
    bin/elasticsearch-plugin install analysis-smartcn
    bin/elasticsearch-plugin install analysis-stempel
    bin/elasticsearch-plugin install analysis-ukrainian
    bin/elasticsearch-plugin install discovery-file
    bin/elasticsearch-plugin install ingest-attachment
    bin/elasticsearch-plugin install ingest-geoip
    bin/elasticsearch-plugin install ingest-user-agent
    bin/elasticsearch-plugin install mapper-attachments
    bin/elasticsearch-plugin install mapper-size
    bin/elasticsearch-plugin install mapper-murmur3
    bin/elasticsearch-plugin install lang-javascript
    bin/elasticsearch-plugin install lang-python
    bin/elasticsearch-plugin install repository-hdfs
    bin/elasticsearch-plugin install repository-s3
    bin/elasticsearch-plugin install repository-azure
    bin/elasticsearch-plugin install repository-gcs
    bin/elasticsearch-plugin install store-smb
    bin/elasticsearch-plugin install discovery-ec2
    bin/elasticsearch-plugin install discovery-azure-classic
    bin/elasticsearch-plugin install discovery-gce
]]

require "quickframework.init"
require "svrFunc"
require "configInclude"
require "sharedataLib"
require("cluster")
local skynet = require "skynet"
local netpack = require "skynet.netpack"
local profile = require "skynet.profile"
local elasticSearchCenter = include("elasticSearchCenter"):shareInstance()

local ti = {}

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        profile.start()

        elasticSearchCenter:dispatchCmd(session, source, cmd, ...)

        local time = profile.stop()
        if time > 5 then
            gLog.w("elasticSearchCenter:dispatchCmd timeout time=", time, " cmd=", cmd, ...)
            if not ti[cmd] then
                ti[cmd] = {n = 0, ti = 0}
            end
            ti[cmd].n = ti[cmd].n + 1
            ti[cmd].ti = ti[cmd].ti + time
        end
    end)

    -- 设置本服地址
    svrAddrMgr.setSvr(skynet.self(), svrAddrMgr.elasticSearchSvr)
end)