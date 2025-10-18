LUA_VERSION =       5.3
TARGET =            mapSearch.so
CFLAGS =            -O3 -g -Wall -Wshadow -Winline -Wunreachable-code -pedantic -DNDEBUG -Wunused-function
# LUA_INCLUDE_DIR =   $(PREFIX)/include
LUA_INCLUDE_DIR =   ../../skynet/3rd/lua

LNK_FLAGS = -Xlinker --unresolved-symbols=ignore-in-shared-libs
LNX_LDFLAGS = -shared -lstdc++ -lm
MAC_LDFLAGS = -shared -undefined dynamic_lookup -lstdc++ -lm

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) -fPIC
OBJS =              lua-mapSearch.o mapSearch.o wrapper.o

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
	$(CC) -c $(CFLAGS) $(BUILD_CFLAGS) -std=gnu++11 -o $@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS)

demo:
	$(CC) -o $@ -I./ -I$(LUA_INCLUDE_DIR) -std=gnu++11 -lstdc++ -lm astar_demo.cpp

demo2:
	g++ astar_demo2.cpp mapSearch.cpp -o $@ -g -I./ -I$(/usr/local/include) -lm -llua -ldl -std=gnu++11

main2:
	g++ main2.cpp -o main2 -g -llua -ldl

clean:
	rm -f *.o *.so demo demo2 test
