TARGET =            libtolua++.a
PREFIX =            /usr/local
CFLAGS =            -g -O2 -Wall -ansi -pedantic -DNDEBUG -std=gnu99
LUA_INCLUDE_DIR =   ../../../../skynet/3rd/lua

LNX_LDFLAGS = -shared -fPIC
MAC_LDFLAGS = -bundle -undefined dynamic_lookup

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -shared -fPIC -I$(LUA_INCLUDE_DIR) -I./
OBJS =              tolua_event.o tolua_is.o tolua_map.o tolua_push.o tolua_to.o

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"
	@echo "  * clean"

.c.o:
	$(CC) -c $(CFLAGS) $(BUILD_CFLAGS) -o $@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGET): $(OBJS)
	ar rcu $@ $(OBJS)
	ranlib $@
	#$(CC) $(LDFLAGS) -o libtolua++.so $(OBJS)

clean:
	rm -f *.o *.so *.a
