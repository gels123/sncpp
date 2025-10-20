--[[
    中台写日志异常处理文件
--]]
local skynet = require("skynet")
local lfs = require("lfs")
local json = require("json")
local svrFunc = require("svrFunc")
local logCenter = require("logCenter"):shareInstance()
local fileWriter = class("fileWriter")

-- 构造
function fileWriter:ctor()
    -- 文件路径
    self.fileDir = lfs.currentdir()
    -- 文件名
    self.fileName = string.format("%s", "logzt_err")
    -- 最大文件大小
    self.maxFileSize = 1024000000
    -- 当前文件大小
    self.curFileSize = 0
    -- 写入文件
    self.file = nil
    -- 今日零点的UTC时间戳
    self.today0clock = 0
    -- 加载文件次数
    self.loadCnt = 0
end

-- 初始化
function fileWriter:init(fileDir, fileName)
    gLog.i("==fileWriter:init begin==")
    -- 文件路径
    if fileDir then
        self.fileDir = fileDir
    end
    -- 文件名
    if fileName then
        self.fileName = string.format("%s", fileName)
    end
    -- 读取异常处理文件并重发
    self:loadFile()
    gLog.i("==fileWriter:init end==")
end

-- 生成文件对象
function fileWriter:newFiles()
    local sq = logCenter:getSq("fileWriter")
    sq(function()
        if self.file then
            return
        end
        if not lfs.exist(self.fileDir) then
            lfs.mkdir(self.fileDir)
        end
        if not lfs.exist(self.fileDir) then
            self.fileDir = lfs.currentdir()
        end
        gLog.i("fileWriter:newFiles fileDir=", self.fileDir, "fileName=", self.fileName)
        local infoFilename = self:getNewFile(self.fileDir, self.fileName)
        gLog.i("fileWriter:newFiles infoFilename=", infoFilename)
        -- 打开文件
        self.file = io.open(infoFilename, "w")
        if not self.file then
            gLog.e("fileWriter:newFiles error: open file failed.", infoFilename)
        else
            -- 设置缓冲大小
            self.curFileSize = 0
            self.file:setvbuf("full", 8192)
            gLog.i("fileWriter:newFiles open file success.", infoFilename)
        end
    end)
end

-- 获取文件名
function fileWriter:getNewFile(path, fileName)
    local curTime = math.floor(svrFunc.systemTime())
    local now = os.date("*t", curTime)
    local curYear = now.year % 100
    local matchstr = fileName .. ".(%d+)-(%d+)-(%d+).(%d+)"
    local maxIdx = 0
    for file in lfs.dir(path) do
        -- 检测年月日是否匹配
        local tmpyear, tmpmonth, tmpday, tmpIdx = string.match(file, matchstr)
        if tmpyear and tonumber(tmpyear) == curYear and tmpmonth and tonumber(tmpmonth) == now.month and tmpday and tonumber(tmpday) == now.day and tmpIdx then
            tmpIdx = tonumber(tmpIdx)
            if maxIdx < tmpIdx then
                maxIdx = tmpIdx
            end
        end
    end
    -- print("needRename == ",fileName,", maxIdx=",maxIdx)
    maxIdx = maxIdx + 1
    local newfilename = string.format("%s/%s.%d-%d-%d.%d", path, fileName, curYear, now.month, now.day, maxIdx)
    -- print("new file max idx =",maxIdx,newfilename)
    -- 获取当前时间的时分秒
    self:takeToday0clock(curTime)

    return newfilename
end

-- 获得当前时间0点
function fileWriter:takeToday0clock(curTime)
    local h = tonumber(os.date("%H", curTime))
    local m = tonumber(os.date("%M", curTime))
    local s = tonumber(os.date("%S", curTime))
    self.today0clock = curTime - (h * 3600 + m * 60 + s)
    -- print("fileWriter:takeToday0clock =", self.today0clock)
end

-- 将缓存输出到文件
function fileWriter:flush()
    if self.file and io.type(self.file) == "file" then
        self.file:flush()
    end
end

-- 文件关闭
function fileWriter:close()
    local sq = logCenter:getSq("fileWriter")
    sq(function()
        if self.file and io.type(self.file) == "file" then
            self.file:flush()
            self.file:close()
            self.file = nil
            self.curFileSize = 0
        end
    end)
end

-- 检测是否需要换新文件名字
function fileWriter:checkNew(curTime)
    curTime = math.floor(curTime)
    if (curTime > self.today0clock + 86400) or self.curFileSize >= self.maxFileSize then
        self:takeToday0clock(curTime)
        return true
    end
    return false
end

-- 写文件(注意：文件数据以换行符'\r'作为分隔符, 所以str中不能含有换行符)
function fileWriter:writeFile(str)
    if dbconf.DEBUG then
        gLog.d("fileWriter:writeFile str=", str)
    end
    if type(str) == "string" and #str > 0 then
        -- 生成文件对象
        if not self.file then
            self:newFiles()
        end
        if self.file then
            local curTime = svrFunc.systemTime()
            self.file:write(curTime.."#"..str.."#\n")
            self.file:flush()
            self.curFileSize = self.curFileSize + #str
            if self:checkNew(curTime) then
                self:close()
                self:newFiles()
            end
        end
    end
end

-- 读取异常处理文件并重发
function fileWriter:loadFile()
    local sq = logCenter:getSq("fileWriter")
    sq(function()
        -- 防止陷入死循环
        self.loadCnt = self.loadCnt + 1
        if self.loadCnt >= 10000 then
            svrFunc.exception(string.format("fileWriter:loadFile exception: in endless loop"))
            return
        end
        -- 遍历读取文件, 并执行文件sql
        local fileArray = {}
        if not lfs.exist(self.fileDir) then
            self.fileDir = lfs.currentdir()
        end
        gLog.i("fileWriter:loadFile begin=", logCenter.kid, self.loadCnt, "fileDir=", self.fileDir, "fileName=", self.fileName)
        for file in lfs.dir(self.fileDir) do
            if string.find(file, self.fileName) then
                table.insert(fileArray, file)
            end
        end
        if #fileArray <= 0 then
            gLog.i("fileWriter:loadFile end1=", logCenter.kid, self.loadCnt)
            return
        end
        local matchstr = self.fileName .. ".(%d+)-(%d+)-(%d+).(%d+)"
        table.sort(fileArray, function (a, b) -- 文件按时间由早到晚排序
            local y1, m1, d1, i1 = string.match(a, matchstr)
            local y2, m2, d2, i2 = string.match(b, matchstr)
            y1, m1, d1, i1, y2, m2, d2, i2 = tonumber(y1), tonumber(m1), tonumber(d1), tonumber(i1), tonumber(y2), tonumber(m2), tonumber(d2), tonumber(i2)
            -- gLog.d("fileWriter:loadFile2 sort a=", y1, m1, d1, i1, "b=", y2, m2, d2, i2)
            if y1 and m1 and d1 and i1 and y2 and m2 and d2 and i2 then
                if y1 == y2 then
                    if m1 == m2 then
                        if d1 == d2 then
                            return i1 < i2
                        else
                            return d1 < d2
                        end
                    else
                        return m1 < m2
                    end
                else
                    return y1 < y2
                end
            end
        end)
        gLog.i("fileWriter:loadFile fileArray=", #fileArray, table2string(fileArray))
        local successArray = {}
        for _,file in ipairs(fileArray) do
            xpcall(function ()
                local filename = string.format("%s/%s", self.fileDir, file)
                for line in io.lines(filename) do
                    local tmp = svrFunc.split(line, "#")
                    gLog.i("fileWriter:loadFile do=", file, tmp[1], tmp[2])
                    if tmp[1] and tmp[2] then
                        local data = json.decode(tmp[2])
                        if type(data) == "table" then
                            skynet.fork(function()
                                logCenter.logMgr:writeLogHttp(data)
                            end)
                        end
                    end
                end
                table.insert(successArray, file)
            end, svrFunc.exception)
        end
        -- 删除文件
        for _,file in pairs(successArray) do
            xpcall(function ()
                local filename = string.format("%s/%s", self.fileDir, file)
                local shell = string.format("rm -f %s", filename)
                local ret = io.popen(shell)
                gLog.i("fileWriter:loadFile shell,ret=", shell, ret)
            end, svrFunc.exception)
        end
        gLog.i("fileWriter:loadFile end2=", logCenter.kid, self.loadCnt)
    end)
end

return fileWriter
