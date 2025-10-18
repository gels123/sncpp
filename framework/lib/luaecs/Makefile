TARGET =            ecs.so
CFLAGS =            -O3 -Wall -pedantic -DNDEBUG -g -std=gnu99 -fpic -DTEST_LUAECS
LUA_INCLUDE_DIR =   ../../skynet/3rd/lua
SKYNET_INCLUDE_DIR = ../../skynet/skynet-src

LNX_LDFLAGS = -shared
MAC_LDFLAGS = -bundle -undefined dynamic_lookup

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -fPIC -I$(LUA_INCLUDE_DIR) -I$(SKYNET_INCLUDE_DIR) -I../../skynet/lualib-src
OBJS =              luaecs.o ecs_group.o ecs_persistence.o ecs_template.o ecs_capi.o ecs_entityid.o ecs_cache.o

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"

.c.o:
	$(CC) -c $(CFLAGS) $(BUILD_CFLAGS) -o $@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS)

clean:
	rm -f *.o *.so

