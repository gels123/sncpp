--[[
	拆分字符串，每N个utf8字符组成一个字符串

	@param s 			字符串
	@param n 		 	每组的数量
	@param filterSpace 	是否过滤空白字符，默认过滤
--]]
function splitIntoGroupOfNumUtf8( s, n, filterSpace )
	if "string" ~= type(s) then
		return
	end

	if "number" ~= type(n) then
		return
	end

	-- 每组的数量最低为1
	local splitNumMin = 1
	if n < splitNumMin then
		return
	end

	-- 默认过滤空白字符
	if nil == filterSpace then
		filterSpace = true
	end
	local utf8Array = {}
	for _, cNum in utf8.codes(s) do
		local c = utf8.char(cNum)
		if filterSpace then
			if not string.match(c, "%s") then
				table.insert(utf8Array, c)
			end
		else
			table.insert(utf8Array, c)
		end
	end

	local len = #utf8Array
	if 0 == len then
		return
	end

	-- 如果是1个utf8为一个字符串，那么直接返回 utf8Array
	if splitNumMin == n then
		return utf8Array
	end

	-- utf8字符的长度小于等于一组的字符数量，一整个字符串为一组
	if len <= n then
		return { table.concat(utf8Array) }
	end

	local splitNum = len - (n - 1)
	local ret = {}
	for i = 1, splitNum do
		table.insert(ret, table.concat(utf8Array, nil, i, i + n - 1))
	end

	return ret
end

local function testing()
	local s = "a b c d🚠🛥我 爱 中 国🚠🛥efg 🏎 🚓 🚠 🛥🚄🚐 🚈🚲🚲hij k"
	-- s = "الأمير 🚠🛥%{nick🚠🛥name}🚠🛥 أرسل لك رسالة صو🚠🛥تية🚠🛥"
	local n = 3
	local ret = splitIntoGroupOfNumUtf8( s, n )
	if ret then
		for i,v in ipairs(ret) do
			print(i,v)
		end
	end
end

-- testing()