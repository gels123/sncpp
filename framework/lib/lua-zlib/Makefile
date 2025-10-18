# This Makefile is based on LuaSec's Makefile. Thanks to the LuaSec developers.
# Inform the location to intall the modules
# LUACPATH ?= /usr/lib/lua/5.1
LUACPATH   ?= -I../../skynet/skynet-src -I../../skynet/3rd/lua
INCDIR   ?= -I../../skynet/skynet-src -I../../skynet/3rd/lua
LIBDIR   ?= -L/usr/local/lib
# SKYNET_INC = ../../skynet/skynet-src
# For Mac OS X: set the system version
MACOSX_VERSION = 10.4

CMOD = zlib.so
OBJS = lua_zlib.o

# modify hsx
# LIBS = -lz -llua -lm
LIBS = -lz -lm
WARN = -Wall -pedantic

BSD_CFLAGS  = -O2 -g -std=gnu99 -fPIC $(WARN) $(INCDIR)
BSD_LDFLAGS = -O -shared -fPIC $(LIBDIR)

LNX_CFLAGS  = -O2 -fPIC -g -std=gnu99 $(WARN) $(INCDIR)
LNX_LDFLAGS = -O -shared -fPIC $(LIBDIR)

MAC_ENV     = env MACOSX_DEPLOYMENT_TARGET='$(MACVER)'
MAC_CFLAGS  = -O2 -fPIC -fno-common -g -std=gnu99 $(WARN) $(INCDIR)
MAC_LDFLAGS = -bundle -undefined dynamic_lookup -fPIC $(LIBDIR)

CC = gcc
LD = $(MYENV) gcc
CFLAGS  = $(MYCFLAGS)
LDFLAGS = $(MYLDFLAGS)

.PHONY: all clean install none linux bsd macosx

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * bsd"
	@echo "  * macosx"

install: $(CMOD)
	cp $(CMOD) $(LUACPATH)

uninstall:
	rm $(LUACPATH)/zlib.so

linux:
	@$(MAKE) $(CMOD) MYCFLAGS="$(LNX_CFLAGS)" MYLDFLAGS="$(LNX_LDFLAGS)" INCDIR="$(INCDIR)" LIBDIR="$(LIBDIR)"

bsd:
	@$(MAKE) $(CMOD) MYCFLAGS="$(BSD_CFLAGS)" MYLDFLAGS="$(BSD_LDFLAGS)" INCDIR="$(INCDIR)" LIBDIR="$(LIBDIR)"

macosx:
	@$(MAKE) $(CMOD) MYCFLAGS="$(MAC_CFLAGS)" MYLDFLAGS="$(MAC_LDFLAGS)" MYENV="$(MAC_ENV)" INCDIR="$(INCDIR)" LIBDIR="$(LIBDIR)"

clean:
	rm -f $(OBJS) $(CMOD)

.c.o:
	$(CC) -c $(CFLAGS) $(INCDIR) -o $@ $<

$(CMOD): $(OBJS)
	$(LD) $(LDFLAGS) $(LIBDIR) $(OBJS) $(LIBS) -o $@
