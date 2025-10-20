##########################################################################################
# Platform auto detect
##########################################################################################
SUPPORTED_PLATFORMS := linux darwin
PLATFORMNAME        ?= $(shell echo $(shell uname) | tr "[:upper:]" "[:lower:]")
$(if $(findstring $(PLATFORMNAME),$(SUPPORTED_PLATFORMS)),,$(error "Unsupported os, must be one of '$(SUPPORTED_PLATFORMS)'"))

##########################################################################################
# Compile commands
##########################################################################################
.PHONY: all darwin macosx clean help

all: $(PLATFORMNAME)

linux:
	@echo "========== make skynet start =========="
	#cd 3rd/jemalloc && ./autogen.sh --with-jemalloc-prefix=je_ --enable-prof --with-malloc-conf=background_thread:true,dirty_decay_ms:3000,muzzy_decay_ms:3000 修改jemalloc参数
	$(shell find ./skynet/3rd/jemalloc -type f -name "*.sh" -exec chmod +x {} \;)
	cd ./skynet;make clean;make linux MALLOC_STATICLIB= SKYNET_DEFINES="-DNOUSE_JEMALLOC"
	#cd ./skynet;make clean;make linux SKYNET_DEFINES=""
	@echo "========== make skynet end =========="

	@echo "========== make lua-json start =========="
	cd ./lib/lua-json;make linux
	@echo "========== make lua-json end =========="

	@echo "========== make lua-encrypt start =========="
	cd ./lib/lua-encrypt;make linux
	@echo "========== make lua-encrypt end =========="

	@echo "========== make lua-crc32 start =========="
	cd ./lib/lua-crc32;make linux
	@echo "========== make lua-crc32 end =========="

	@echo "========== make lua-lfs start =========="
	cd ./lib/lua-lfs;make linux
	@echo "========== make lua-lfs end =========="

	@echo "========== make lua-zset start =========="
	cd ./lib/lua-zset;make linux
	@echo "========== make lua-zset end =========="

	@echo "========== make lua-zlib start =========="
# 	cd ./lib/lua-zlib;make linux
	@echo "========== make lua-zlib end =========="

	@echo "========== make lua-curl start =========="
# 	cd ./lib/lua-curl;make linux
	@echo "========== make lua-curl end =========="

	@echo "========== make lua-timer start =========="
	cd ./lib/lua-timer;make linux
	@echo "========== make lua-timer end =========="

	@echo "========== make lua-chash start =========="
	cd ./lib/lua-chash;make linux
	@echo "========== make lua-chash end =========="

	@echo "========== make lua-bit32 start =========="
	cd ./lib/lua-bit32;make linux
	@echo "========== make lua-bit32 end =========="

	@echo "========== make lua-protobuf start =========="
	cd ./lib/lua-protobuf;make linux
	@echo "========== make lua-protobuf end =========="

	@echo "========== make lua-snapshot start =========="
	cd ./lib/lua-snapshot;make linux
	@echo "========== make lua-snapshot end =========="

	@echo "========== make lua-fixedpoint64 start =========="
	cd ./lib/lua-fixedpoint64;make linux
	@echo "========== make lua-fixedpoint64 end =========="

	@echo "========== make lua-socket start =========="
	cd ./lib/lua-socket;make linux
	@echo "========== make lua-socket end =========="

	@echo "========== make lua-snowflake start =========="
	cd ./lib/lua-snowflake;make linux
	@echo "========== make lua-snowflake end =========="

	@echo "========== make lua-conhash start =========="
	cd ./lib/lua-conhash;make linux
	@echo "========== make lua-conhash end =========="

	@echo "========== make lua-extra start =========="
	cd ./lib/lua-extra;make linux
	@echo "========== make lua-extra end =========="

	@echo "========== make luasql start =========="
# 	cd ./lib/luasql;make lmysql
	@echo "========== make luasql end =========="

	@echo "========== make luaecs start =========="
	cd ./lib/luaecs;make linux
	@echo "========== make luaecs end =========="

	@echo "========== make libfaketime start =========="
	cd ./lib/libfaketime;make all
	@echo "========== make libfaketime end =========="

	@echo "========== make lua-map start =========="
# 	cd ./lib/lua-map;make linux
	@echo "========== make lua-map end =========="

	@echo "========== make lua-aoi start =========="
	cd ./lib/lua-aoi;make linux
	@echo "========== make lua-aoi end =========="

	@echo "========== make lua-aoi2 start =========="
# 	cd ./lib/lua-aoi2/simple;make linux
# 	cd ./lib/lua-aoi2/link;make linux
	@echo "========== make lua-aoi2 end =========="

	@echo "========== make lua-mapsearch start =========="
# 	cd ./lib/lua-mapsearch;make linux
	@echo "========== make lua-mapsearch end =========="

	@echo "========== make lua-enet start =========="
# 	cd ./lib/lua-enet;make linux
	@echo "========== make lua-enet end =========="

	@echo "========== make lua-kcp start =========="
# 	cd ./lib/lua-kcp;make linux
	@echo "========== make lua-kcp end =========="

	@echo "========== make tolua++ start =========="
# 	#cd ./lib/tolua++; cmake .;
# 	#cd ./lib/tolua++;make;rm -rf src/*.cmake src/lib/*.cmake src/bin/*.cmake src/tests/*.cmake CMakeFiles src/CMakeFiles src/lib/CMakeFiles src/bin/CMakeFiles src/tests/CMakeFiles CMakeCache*;
# 	cd ./lib/tolua++/src/lib;make linux
# 	cd ./lib/tolua++/src/bin;make linux
	@echo "========== make tolua++ end =========="

	@echo "========== copy libs & rm *.o start =========="
	find ./lib -name "*.so" | xargs -I {} mv -f {} ../bin
	find ./lib -name "*.a" | xargs -I {} mv -f {} ../bin
	mv ./skynet/skynet ../bin
	mv ./skynet/3rd/lua/lua ../bin
	find ./ -name *.o | xargs rm -f
	@echo "========== copy libs & rm *.o end =========="

macosx: darwin

darwin:
	@echo "========== make skynet start =========="
	cd ./skynet;make clean;make macosx MALLOC_STATICLIB= SKYNET_DEFINES="-DNOUSE_JEMALLOC"
	@echo "========== make skynet end =========="

	@echo "========== make lua-json start =========="
	cd ./lib/lua-json;make macosx
	@echo "========== make lua-json end =========="

	@echo "========== make lua-encrypt start =========="
	cd ./lib/lua-encrypt;make macosx
	@echo "========== make lua-encrypt end =========="

	@echo "========== make lua-crc32 start =========="
	cd ./lib/lua-crc32;make macosx
	@echo "========== make lua-crc32 end =========="

	@echo "========== make lua-lfs start =========="
	cd ./lib/lua-lfs;make macosx
	@echo "========== make lua-lfs end =========="

	@echo "========== make lua-zset start =========="
	cd ./lib/lua-zset;make macosx
	@echo "========== make lua-zset end =========="

	@echo "========== make lua-zlib start =========="
	cd ./lib/lua-zlib;make macosx
	@echo "========== make lua-zlib end =========="

	@echo "========== make lua-curl start =========="
# 	cd ./lib/lua-curl;make macosx
	@echo "========== make lua-curl end =========="

	@echo "========== make lua-timer start =========="
	cd ./lib/lua-timer;make macosx
	@echo "========== make lua-timer end =========="

	@echo "========== make lua-chash start =========="
	cd ./lib/lua-chash;make macosx
	@echo "========== make lua-chash end =========="

	@echo "========== make lua-bit32 start =========="
	cd ./lib/lua-bit32;make macosx
	@echo "========== make lua-bit32 end =========="

	@echo "========== make lua-protobuf start =========="
	cd ./lib/lua-protobuf;make macosx
	@echo "========== make lua-protobuf end =========="

	@echo "========== make lua-snapshot start =========="
	cd ./lib/lua-snapshot;make macosx
	@echo "========== make lua-snapshot end =========="

	@echo "========== make lua-fixedpoint64 start =========="
	cd ./lib/lua-fixedpoint64;make macosx
	@echo "========== make lua-fixedpoint64 end =========="

	@echo "========== make lua-socket start =========="
	cd ./lib/lua-socket;make macosx
	@echo "========== make lua-socket end =========="

	@echo "========== make lua-snowflake start =========="
	cd ./lib/lua-snowflake;make macosx
	@echo "========== make lua-snowflake end =========="

	@echo "========== make lua-conhash start =========="
	cd ./lib/lua-conhash;make macosx
	@echo "========== make lua-conhash end =========="

	@echo "========== make lua-extra start =========="
	cd ./lib/lua-extra;make macosx
	@echo "========== make lua-extra end =========="

	@echo "========== make luasql start =========="
# 	cd ./lib/luasql;make lmysql
	@echo "========== make luasql end =========="

	@echo "========== make luaecs start =========="
	cd ./lib/luaecs;make macosx
	@echo "========== make luaecs end =========="

	@echo "========== make libfaketime start =========="
	cd ./lib/libfaketime;make all
	@echo "========== make libfaketime end =========="

	@echo "========== make lua-map start =========="
# 	#cd ./lib/lua-map;make macosx
	@echo "========== make lua-map end =========="

	@echo "========== make lua-aoi start =========="
	#cd ./lib/lua-aoi;make macosx
	@echo "========== make lua-aoi end =========="

	@echo "========== make lua-aoi2 start =========="
# 	#cd ./lib/lua-aoi2/simple;make macosx
# 	#cd ./lib/lua-aoi2/link;make macosx
	@echo "========== make lua-aoi2 end =========="

	@echo "========== make lua-mapsearch start =========="
# 	#cd ./lib/lua-mapsearch;make macosx
	@echo "========== make lua-mapsearch end =========="

	@echo "========== make lua-enet start =========="
# 	#cd ./lib/lua-enet;make macosx
	@echo "========== make lua-enet end =========="

	@echo "========== make lua-kcp start =========="
# 	#cd ./lib/lua-kcp;make macosx
	@echo "========== make lua-kcp end =========="

	@echo "========== make tolua++ start =========="
# 	#cd ./lib/tolua++; cmake .;
# 	#cd ./lib/tolua++;make;rm -rf src/*.cmake src/lib/*.cmake src/bin/*.cmake src/tests/*.cmake CMakeFiles src/CMakeFiles src/lib/CMakeFiles src/bin/CMakeFiles src/tests/CMakeFiles CMakeCache*;
# 	#cd ./lib/tolua++/src/lib;make macosx
# 	#cd ./lib/tolua++/src/bin;make macosx
	@echo "========== make tolua++ end =========="

	@echo "========== copy libs & rm *.o start =========="
	find ./lib -name "*.so" | xargs -I {} mv -f {} ../bin
	find ./lib -name "*.a" | xargs -I {} mv -f {} ../bin
	mv ./skynet/skynet ../bin
	mv ./skynet/3rd/lua/lua ../bin
	find ./ -name *.o | xargs rm -f
	@echo "========== copy libs & rm *.o end =========="

clean:
	@echo "========== clean skynet start =========="
	cd ./skynet;make cleanall
	@echo "========== clean skynet end =========="

	@echo "========== clean lua-json start =========="
	cd ./lib/lua-json;make clean
	@echo "========== clean lua-json end =========="

	@echo "========== clean lua-encrypt start =========="
	cd ./lib/lua-encrypt;make clean
	@echo "========== clean lua-encrypt end =========="

	@echo "========== clean lua-crc32 start =========="
	cd ./lib/lua-crc32;make clean
	@echo "========== clean lua-crc32 end =========="

	@echo "========== clean lua-lfs start =========="
	cd ./lib/lua-lfs;make clean
	@echo "========== clean lua-lfs end =========="

	@echo "========== clean lua-curl start =========="
	cd ./lib/lua-curl;make clean
	@echo "========== clean lua-curl end =========="

	@echo "========== clean lua-zset start =========="
	cd ./lib/lua-zset;make clean
	@echo "========== clean lua-zset end =========="

	@echo "========== clean lua-zlib start =========="
	cd ./lib/lua-zlib;make clean
	@echo "========== clean lua-zlib end =========="

	@echo "========== clean lua-timer start =========="
	cd ./lib/lua-timer;make clean
	@echo "========== clean lua-timer end =========="

	@echo "========== clean lua-chash start =========="
	cd ./lib/lua-chash;make clean
	@echo "========== clean lua-chash end =========="

	@echo "========== clean lua-bit32 start =========="
	cd ./lib/lua-bit32;make clean
	@echo "========== clean lua-bit32 end =========="

	@echo "========== clean lua-protobuf start =========="
	cd ./lib/lua-protobuf;make clean
	@echo "========== clean lua-protobuf end =========="

	@echo "========== clean lua-snapshot start =========="
	cd ./lib/lua-snapshot;make clean
	@echo "========== clean lua-snapshot end =========="

	@echo "========== clean lua-fixedpoint64 start =========="
	cd ./lib/lua-fixedpoint64;make clean
	@echo "========== clean lua-fixedpoint64 end =========="

	@echo "========== clean lua-socket start =========="
	cd ./lib/lua-socket;make clean
	@echo "========== clean lua-socket end =========="

	@echo "========== clean lua-snowflake start =========="
	cd ./lib/lua-snowflake;make clean
	@echo "========== clean lua-snowflake end =========="

	@echo "========== clean lua-conhash start =========="
	cd ./lib/lua-conhash;make clean
	@echo "========== clean lua-conhash end =========="

	@echo "========== clean lua-extra start =========="
	cd ./lib/lua-extra;make clean
	@echo "========== clean lua-extra end =========="

	@echo "========== clean libfaketime start =========="
	cd ./lib/libfaketime;make clean
	@echo "========== clean libfaketime end =========="

	@echo "========== clean luasql start =========="
	cd ./lib/luasql;make clean
	@echo "========== clean luasql end =========="

	@echo "========== clean luaecs start =========="
	cd ./lib/luaecs;make clean
	@echo "========== clean luaecs end =========="

	@echo "========== clean lua-map start =========="
	cd ./lib/lua-map;make clean
	@echo "========== clean lua-map end =========="

	@echo "========== clean lua-aoi start =========="
	cd ./lib/lua-aoi;make clean
	@echo "========== clean lua-aoi end =========="

	@echo "========== clean lua-aoi2 start =========="
	cd ./lib/lua-aoi2/simple;make clean
	cd ./lib/lua-aoi2/link;make clean
	@echo "========== clean lua-aoi2 end =========="

	@echo "========== clean lua-mapsearch start =========="
	cd ./lib/lua-mapsearch;make clean
	@echo "========== clean lua-mapsearch end =========="

	@echo "========== clean lua-enet start =========="
	cd ./lib/lua-enet;make clean
	@echo "========== clean lua-enet end =========="

	@echo "========== clean lua-kcp start =========="
	cd ./lib/lua-kcp;make clean
	@echo "========== clean lua-kcp end =========="

	@echo "========== clean tolua++ start =========="
	#cd ./lib/tolua++;make clean;rm -rf src/*.cmake src/lib/*.cmake src/bin/*.cmake src/tests/*.cmake CMakeFiles src/CMakeFiles src/lib/CMakeFiles src/bin/CMakeFiles src/tests/CMakeFiles CMakeCache*;
	cd ./lib/tolua++/src/lib;make clean
	cd ./lib/tolua++/src/bin;make clean
	@echo "========== clean tolua++ end =========="

help:
	@echo "  * linux"
	@echo "  * macosx"
	@echo "  * clean"
