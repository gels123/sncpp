# lua版本的googleapi接口
由于googleapi未提供lua版本的api接口, 而go语言版本接口很容易编译未so供c调用, 所以lua版本的googleapi接口的实现采用c调用so(go编译得到)实现。
# 目前支持的googleapi接口
1. 谷歌支付(二次验证)
####usage:
```
    local lfs = require("lfs")
    local googleapi = require("googleapi")
    local filename = lfs.currentdir().."/depends/lua-googleapi/xxx.json"
    googleapi:doInit(filename, "")
    
    local packageName = "com.game.xxx"
    local productId = "xxxx01"
    local token = "meklgmjahojnmegifiniahkc.AO-J1OwmkMOehJOgI-H6YzSXBHWPyYRdLxrCcBXwIWiUqPLWGTQLkvA946Wz8GXnUmg21CbZW1RLiJOT_Ge-Gv-UlRJpgY5eNA"
    local ret, err = googleapi:doVerify(packageName, productId, token)
    print("=========sdfadfadfadsfadf======", ret, err)
```
2. fcm推送(推送给个人、推送给主题、订阅主题、取消订阅等)
https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages?hl=zh-cn
####usage:
```

```

3. 其他api后续有用的时再补充添加。