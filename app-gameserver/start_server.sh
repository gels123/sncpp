#!/usr/bin/env bash
chmod +x ../bin/skynet ../bin/lua
if [[ ! -d "./logs" ]]; then
	mkdir ./logs
fi
chmod 777 ./logs
ulimit -n 65535
#删除启动成功标志文件
if [[ -f "./.startsuccess_game" ]]; then
	rm -f ./.startsuccess_game
fi

#开启内存池jemalloc和允许调时间faketime, 两者不可兼得
# backdoor=$(find ../framework/skynet/3rd/jemalloc/ -name *.a)
# if [[ $backdoor == "" ]]; then
# 	echo "use faketime but not jemalloc"
# 	rm -f ./faketime.rc && touch ./faketime.rc && chmod 777 ./faketime.rc && echo '+0s' >./faketime.rc
# 	export LD_PRELOAD=./game/lib/libfaketime/src/libfaketime.so
# 	export FAKETIME_TIMESTAMP_FILE="./faketime.rc"
# 	export FAKETIME_UPDATE_TIMESTAMP_FILE=1
# 	export FAKETIME_CACHE_DURATION=5
# else
# 	echo "use jemalloc but not faketime"
# 	export MALLOC_CONF="background_thread:true,dirty_decay_ms:3000,muzzy_decay_ms:3000"
# fi

#启动进程
# if [[ ! -f "./dbconflocal.lua" ]]; then
# 	#后台启动
# 	if [[ -f "./game/gamestartconf_daemon" ]]; then
# 		rm -f ./game/gamestartconf_daemon
# 	fi
# 	cp ./game/gamestartconf ./game/gamestartconf_daemon
# 	sed -i 's/-- daemon/daemon/g' ./game/gamestartconf_daemon
# 	$(pwd)/../framework/skynet/skynet game/gamestartconf_daemon
# else
	#控制台启动
	if [[ -f "./game/gamestartconf_daemon" ]]; then
		rm -f ./game/gamestartconf_daemon
	fi
	$(pwd)/../bin/skynet game/gamestartconf
# fi
