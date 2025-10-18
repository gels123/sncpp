JUDY_STATICLIB = ./judy/src
JUDY_INC = ./judy/src

LUA_VERSION =       5.4
TARGET =            judy.so
PREFIX =            /usr/local
CFLAGS =            -O3 -Wall -pedantic -DNDEBUG -DUSE_MEM_HOOK
CZSET_CFLAGS =      -fpic 
LUA_INCLUDE_DIR =   ../../skynet/3rd/lua

LNX_LDFLAGS = -shared -L$(JUDY_STATICLIB) -lJudy -L$(PREFIX)/lib
MAC_LDFLAGS = -bundle -undefined dynamic_lookup -L$(JUDY_STATICLIB) -lJudy -L$(PREFIX)/lib

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) -I$(SKYNET_INC) $(CZSET_CFLAGS) -I$(JUDY_INC) -I$(PREFIX)/include
OBJS =              lua-judy.o

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * macosx"

.c.o:
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $(BUILD_CFLAGS) -o $@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS)

clean:
	rm -f *.o *.so

