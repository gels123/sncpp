LUA_VERSION =       5.4
TARGET =            luagoogleapi.so
CFLAGS =            -O3 -g -Wall -Wshadow -Winline -Wunreachable-code -pedantic -DNDEBUG -Wunused-function -std=gnu99
LUA_INCLUDE_DIR =   ../../skynet/3rd/lua
LUACLIB =           ../../luaclib

CC = gcc

all:
	@echo "Usage: $(MAKE) <platform>"
	@echo "  * linux"
	@echo "  * clean"

linux:
	# go mod init luagoogleapi
	# go mod tidy
	go build -buildmode=c-shared -o $(LUACLIB)/libgoogleapi.so googleapi.go
	chmod +x $(LUACLIB)/libgoogleapi.so
	gcc -o $(LUACLIB)/$(TARGET) -shared -fPIC -Wl,-rpath=./ -I$(LUA_INCLUDE_DIR) -I$(LUACLIB) -L$(LUACLIB)  lua-googleapi.c -lgoogleapi -lpthread -std=gnu99


clean:
	rm -f *.o *.so *.a libgoogleapi.h $(LUACLIB)/libgoogleapi.h test
