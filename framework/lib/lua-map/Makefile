LUA_VERSION =       5.4
TARGET =            mmomap.so
CFLAGS =            -O3 -g -Wall -Wshadow -Winline -Wunreachable-code -pedantic -DNDEBUG -Wunused-function
LUA_INCLUDE_DIR =   ../../skynet/3rd/lua
TOLUA_DIR =   		../tolua++/src/lib


LNK_FLAGS = -Xlinker --unresolved-symbols=ignore-in-shared-libs
LNX_LDFLAGS = -shared -fPIC -lstdc++ -lm -ldl -I$(TOLUA_DIR) -L$(TOLUA_DIR) -ltolua++
MAC_LDFLAGS = -shared -fPIC -undefined dynamic_lookup -lstdc++ -lm -ldl -I$(TOLUA_DIR) -L$(TOLUA_DIR) -ltolua++

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) -shared -fPIC -I$(TOLUA_DIR)
OBJS =              luammomap.o MmoMap.o NpcInfo.o


all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"
	@echo "  * demo"
	@echo "  * demo2"
	@echo "  * clean"

.c.o:
	$(CC) -c $(CFLAGS) $(BUILD_CFLAGS) -std=gnu99 -o $@ $<

.cpp.o:
	$(CC) -c $(CFLAGS) $(BUILD_CFLAGS) -std=gnu99 -o $@ $<

linux:
	../tolua++/src/bin/tolua++ -o luammomap.cpp mmomap.pkg
	sed -i '5i extern "C" {' luammomap.cpp;
	echo "}" >> luammomap.cpp;
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	../tolua++/src/bin/tolua++ -o luammomap.cpp mmomap.pkg
	sed -i '5i extern "C" {' luammomap.cpp;
	echo "}" >> luammomap.cpp;
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGET): $(OBJS)
	$(CC) -o $@ $(OBJS) $(LDFLAGS)

testmain:
	g++ -o testmain testmain.cpp MmoMap.h MmoMap.cpp -I./ -L./ -I$(TOLUA_DIR) -L$(TOLUA_DIR) -I$(LUA_INCLUDE_DIR) -L$(LUA_INCLUDE_DIR) -ltolua++ -llua -lm -ldl -lstdc++ -std=gnu++11

clean:
	rm -f *.o *.so testmain luammomap.cpp
