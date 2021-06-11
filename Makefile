# Host CC
HOSTCC ?= gcc
# Toolchain prefix and gcc/g++ executables
CHOST ?= arm-none-linux-gnueabi
CROSSCC  ?= $(CHOST)-gcc
CROSSCXX ?= $(CHOST)-g++

# CROSS_DIR is the main directory of the toolchain,
# which is only used for trying to autolocate GCCPLUGIN_DIR,
# that is set to the directory containing gcc-plugin.h
CROSS_DIR ?= $(shell dirname `$(CROSSCC) -print-libgcc-file-name`)
GCCPLUGIN_DIR ?= $(shell find $(CROSS_DIR) -name gcc-plugin.h | head -n 1 | xargs dirname)

# Workaround for gcc<4.8 on arm (see http://gcc.gnu.org/PR45078)
FIX_CPPFLAGS ?= -I$(CURDIR)/include

# If the host is x86_64, but the TC is x86, we need to match the bitness of the TC
ifeq ($(shell uname -m), x86_64)
	# Ask file to follow symlinks (for Linaro TCs)
	ifeq ($(shell if file -L `which $(CROSSCC)` | grep -q 32-bit ; then echo 1 ; fi), 1)
		FIX_CPPFLAGS += -m32
	endif
endif

PLUGIN_CPPFLAGS = $(CPPFLAGS) -I$(GCCPLUGIN_DIR) $(FIX_CPPFLAGS)

PLUGIN = gcc-lua/gcc/gcclua
PLUGINLIB = $(PLUGIN).so

all: | patch $(PLUGINLIB)

patch:
	patch -d gcc-lua -p1 < gcc-lua-prefer-luajit.patch
	patch -d gcc-lua -p1 < gcc-lua-support-gcc11.patch
	patch -d gcc-lua-cdecl -p1 < gcc-lua-cdecl-do-not-mangle-c99-types.patch

unpatch:
	cd gcc-lua && git reset --hard && git clean -fxdq
	cd gcc-lua-cdecl && git reset --hard && git clean -fxdq

clean: unpatch
	$(MAKE) -C gcc-lua clean

test: test-ffi-cdecl test-gcc-lua test-gcc-lua-cdecl
test-ffi-cdecl: $(PLUGINLIB)
	./ffi-cdecl "$(CROSSCC)" test/util.c test/util.lua
	# FIXME: Either I broke it, or this doesn't work anymore...
	#./ffi-cdecl "$(CROSSCXX)" test/sample.cpp test/sample.lua
test-gcc-lua: $(PLUGINLIB)
	$(MAKE) CC="$(CROSSCC)" CXX="$(CROSSCXX)" GCCLUA="../../$(PLUGINLIB)" -C gcc-lua test
test-gcc-lua-cdecl: $(PLUGINLIB)
	$(MAKE) CC="$(CROSSCC)" CXX="$(CROSSCXX)" GCCLUA="../../$(PLUGINLIB)" -C gcc-lua-cdecl test

$(PLUGINLIB): $(GCCVER) $(PLUGIN).c
	$(MAKE) HOST_CC="$(HOSTCC)" TARGET_CC="$(CROSSCC)" CPPFLAGS="$(PLUGIN_CPPFLAGS)" \
		-C gcc-lua gcc
