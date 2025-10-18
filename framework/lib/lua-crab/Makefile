# include ../../skynet.mk

LUA_VERSION =       5.3
TARGETCRAB =        crab.so
TARGETUTF8 =        utf8.so
PREFIX =            /usr/local
CFLAGS =            -O3 -Wall -pedantic -DNDEBUG -DUSE_MEM_HOOK
CZSET_CFLAGS =      -fPIC
LUA_INCLUDE_DIR =   ../../skynet/3rd/lua

LNX_LDFLAGS = -shared
MAC_LDFLAGS = -bundle -undefined dynamic_lookup

CC = gcc
LDFLAGS = $(MYLDFLAGS)

BUILD_CFLAGS =      -I$(LUA_INCLUDE_DIR) $(CZSET_CFLAGS)
OBJSCRAB =             lua-crab.o
OBJUTF8 =              lua-utf8.o

all: $(TARGETCRAB) $(TARGETUTF8)

.c.o:
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $(BUILD_CFLAGS) -o $@ $<

linux:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(LNX_LDFLAGS)"

macosx:
	@$(MAKE) $(TARGET) MYLDFLAGS="$(MAC_LDFLAGS)"

$(TARGETCRAB): $(OBJSCRAB)
	$(CC) $(CZSET_CFLAGS) $(LDFLAGS) -o $@ $(OBJSCRAB)

$(TARGETUTF8): $(OBJUTF8)
	$(CC) $(CZSET_CFLAGS) $(LDFLAGS) -o $@ $(OBJUTF8)
	
clean:
	rm -f *.o *.so

