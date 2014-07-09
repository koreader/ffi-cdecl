# CROSS_DIR is the main directory of the toolchain,
# which is only used for trying to autolocate GCCPLUGIN_DIR,
# that is set to the directory containing gcc-plugin.h
CROSS_DIR ?= /opt/arm-2012.03
GCCPLUGIN_DIR ?= $(shell find $(CROSS_DIR) -name gcc-plugin.h \
                   -exec dirname '{}' \;)

# Host CC
HOSTCC ?= gcc
# Toolchain prefix and gcc/g++ executables
CHOST ?= arm-none-linux-gnueabi
CROSSCC  ?= $(CHOST)-gcc
CROSSCXX ?= $(CHOST)-g++

# Workaround for gcc<4.8 on arm (see http://gcc.gnu.org/PR45078)
FIX_CPPFLAGS ?= -I$(CURDIR)/include

PLUGIN_CPPFLAGS = $(CPPFLAGS) -I$(GCCPLUGIN_DIR) $(FIX_CPPFLAGS)

PLUGIN = gcc-lua/gcc/gcclua
PLUGINLIB = $(PLUGIN).so

all: $(PLUGINLIB)

clean:
	$(MAKE) -C gcc-lua clean

test: test-ffi-cdecl test-gcc-lua test-gcc-lua-cdecl
test-ffi-cdecl: $(PLUGINLIB)
	./ffi-cdecl "$(CROSSCC)" test/util.c > test/util.lua
	./ffi-cdecl "$(CROSSCXX)" test/sample.cpp > test/sample.lua
test-gcc-lua: $(PLUGINLIB)
	$(MAKE) CC="$(CROSSCC)" CXX="$(CROSSCXX)" -C gcc-lua test
test-gcc-lua-cdecl: $(PLUGINLIB)
	$(MAKE) CC="$(CROSSCC)" CXX="$(CROSSCXX)" -C gcc-lua-cdecl test

$(PLUGINLIB): $(GCCVER) $(PLUGIN).c
	$(MAKE) HOST_CC="$(HOSTCC)" TARGET_CC="$(CROSSCC)" CPPFLAGS="$(PLUGIN_CPPFLAGS)" \
		-C gcc-lua gcc
