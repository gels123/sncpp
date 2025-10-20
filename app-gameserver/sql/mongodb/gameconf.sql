
use game_conf

db.conf_cluster.insertOne({"_id":1, "nodeid":1, "nodename":'my_node_game_1', "ip":'127.0.0.1', "web":'127.0.0.1', "listen":'0.0.0.0', "listennodename":'listen_my_node_game_1', "port":2001, "type":3})
db.conf_cluster.insertOne({"_id":10001, "nodeid":10001, "nodename":'my_node_login', "ip":'127.0.0.1', "web":'127.0.0.1', "listen":'0.0.0.0', "listennodename":'listen_my_node_login', "port":2801, "type":1})
db.conf_cluster.insertOne({"_id":10002, "nodeid":10002, "nodename":'my_node_global', "ip":'127.0.0.1', "web":'127.0.0.1', "listen":'0.0.0.0', "listennodename":'listen_my_node_global', "port":2802, "type":2})


db.conf_debug.insertOne({"_id":1, "nodeid":1, "ip":'127.0.0.1', "web":'127.0.0.1', "port":3001})
db.conf_debug.insertOne({"_id":10001, "nodeid":10001, "ip":'127.0.0.1', "web":'127.0.0.1', "port":3801})
db.conf_debug.insertOne({"_id":10002, "nodeid":10002, "ip":'127.0.0.1', "web":'127.0.0.1', "port":3802})


db.conf_gate.insertOne({"_id":1, "nodeid":1, "web":'127.0.0.1', "address":'127.0.0.1', "proxy":'127.0.0.1', "listen":'0.0.0.0', "port":4001})
db.conf_gate.insertOne({"_id":10002, "nodeid":10002, "web":'127.0.0.1', "address":'127.0.0.1', "proxy":'127.0.0.1', "listen":'0.0.0.0', "port":4802})


db.conf_gatepvp.insertOne({"_id": 1, "nodeid": 1, "web":'127.0.0.1', "address":'127.0.0.1', "proxy":'127.0.0.1', "listen":'0.0.0.0', "port":4803})

db.conf_general.insertOne({"_id":1, "id":1, "verifyhost":'127.0.0.1', "verifyiosurl":'/xxx.php', "verifyandroidurl":'/xxx.php', "clientMinVer":'0.00.001', "defaultKid":1, "distributor":1, "defaultKids":'', "verifyiossuburl":'/xxx.php'})


db.conf_http.insertOne({"_id":10001, "nodeid":10001, "host":'127.0.0.1', "web":'127.0.0.1', "listen":'0.0.0.0', "port":5000, "instance":10, "limitbody":81920})


db.conf_ipwhitelist.insertOne({"_id":1, "nodeid":1, "ipList":'127.0.0.1;', "status":1})


db.conf_kingdom.insertOne({"_id":1, "kid":1, "nodeid":1, "status":0, "startTime":'2025-01-01 00:00:00', "isNew":1})


db.conf_login.insertOne({"_id":10001, "nodeid":10001, "host":'127.0.0.1', "web":'127.0.0.1', "listen":'0.0.0.0', "port":6001, "instance":16, "mastername":'.loginMaster', "limitbody":8192})

db.conf_noticehttp.insertOne({"_id":1, "id":1, "host":'127.0.0.1', "url":'/pushserver/message/push'})
