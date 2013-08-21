# CROSS_DIR is the main directory of the toolchain,
# which is only used for trying to autolocate GCCPLUGIN_DIR,
# that is set to the directory containing gcc-plugin.h
CROSS_DIR ?= /opt/arm-2012.03
GCCPLUGIN_DIR ?= $(shell find $(CROSS_DIR) -name gcc-plugin.h \
                   -exec dirname '{}' \;)

# Toolchain prefix and gcc/g++ executables
CHOST ?= arm-none-linux-gnueabi
CROSSCC  ?= $(CHOST)-gcc
CROSSCXX ?= $(CHOST)-g++

# This variable is set to 1 if the toolchain is built for 32 bits.
# We need to know this if we are running a 64 bits system.
# We try to autodetect by checking the gcc executable.
CROSS_32BITS ?= $(shell if file `which $(CROSSCC)` | grep 32-bit >/dev/null; then echo 1; fi)

# CFLAGS and LIBS needed to use any 5.1-compatible Lua implementation
LUA_CFLAGS ?= $(shell pkg-config --cflags luajit 2>/dev/null || \
                      pkg-config --cflags lua5.1 2>/dev/null || \
                      pkg-config --cflags lua    2>/dev/null)
LUA_LIBS   ?= $(shell pkg-config --libs   luajit 2>/dev/null || \
                      pkg-config --libs   lua5.1 2>/dev/null || \
                      pkg-config --libs   lua    2>/dev/null)

# Workaround for gcc<4.8 on arm (see http://gcc.gnu.org/PR45078)
FIX_CFLAGS ?= -I$(CURDIR)/include

PLUGIN_CPPFLAGS = -I$(GCCPLUGIN_DIR) $(LUA_CFLAGS) $(FIX_CFLAGS)

# If the toolchain is built for 32 bits, the plugin also needs to be.
ifeq ($(CROSS_32BITS), 1)
FLAG32 = -m32
endif

PLUGIN = gcc-lua/gcc/gcclua
PLUGINLIB = $(PLUGIN).so
GCCVER = config/gcc-version
CPPABI = config/cpp-abi

all: $(PLUGINLIB)

clean:
	rm -f $(GCCVER) $(CPPABI)
	$(MAKE) -C gcc-lua clean

test: test-ffi-cdecl test-gcc-lua test-gcc-lua-cdecl
test-ffi-cdecl: $(PLUGINLIB)
	./ffi-cdecl $(CROSSCC) test/util.c > test/util.lua
	./ffi-cdecl $(CROSSCXX) test/sample.cpp > test/sample.lua
test-gcc-lua: $(PLUGINLIB)
	$(MAKE) CC=$(CROSSCC) CXX=$(CROSSCXX) -C gcc-lua test
test-gcc-lua-cdecl: $(PLUGINLIB)
	$(MAKE) CC=$(CROSSCC) CXX=$(CROSSCXX) -C gcc-lua-cdecl test

# For detecting the toolchain GCC_VERSION, we preprocess the
# $(GCCVER).c file using the toolchain, but compile using 
# the host machine compiler.
$(GCCVER): $(GCCVER).c
	@echo "config: testing toolchain gcc version"
	$(CROSSCC) -I$(GCCPLUGIN_DIR) -E $(GCCVER).c > $(GCCVER)-E.c
	$(CC) -o $(GCCVER).e $(GCCVER)-E.c
	./$(GCCVER).e > $(GCCVER)
	@rm -f $(GCCVER).e $(GCCVER)-E.c
	@echo

# For detecting if the toolchain is using C++ ABI, we compile
# a stub plugin and check if it is able to run or if it generates
# a symbol lookup error.
$(CPPABI): $(CPPABI).c
	@echo "config: testing if toolchain uses C++ ABI"
	$(CC) $(FLAG32) -shared -Wl,-s -fPIC $(CPPABI).c -o $(CPPABI).so
	if echo | $(CROSSCC) -fplugin=./$(CPPABI).so -E - | grep cpp-abi-ok; then \
		echo "CXX=g++" > $(CPPABI); else echo "CC=gcc" > $(CPPABI); fi
	@rm -f $(CPPABI).so
	@echo

$(PLUGINLIB): $(GCCVER) $(CPPABI) $(PLUGIN).c
	$(MAKE) CPPFLAGS="$(FLAG32) $(PLUGIN_CPPFLAGS) -DGCC_VERSION=`cat $(GCCVER)`" \
                 LUALIBS="$(FLAG32) $(LUA_LIBS)" `cat $(CPPABI)` -C gcc-lua
