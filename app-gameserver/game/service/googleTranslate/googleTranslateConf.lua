--谷歌翻译服务配置
local googleTranslateConf = class("googleTranslateConf")

googleTranslateConf.google_translate_site = "translate.google.com"
googleTranslateConf.google_translate_fee_site = "www.googleapis.com"
googleTranslateConf.YOUR_API_KEY = "xxx" --公司key

--公司自有翻译破解网站
googleTranslateConf.self_translate_site = "1.1.1.1" --正式环境

if dbconf.DEBUG then
	googleTranslateConf.self_translate_site = "a.b.c" --测试
else
	googleTranslateConf.self_translate_site = "1.1.1.1" --正式环境
end

return googleTranslateConf
