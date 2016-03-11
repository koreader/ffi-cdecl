ffi-cdecl
=========

Automated C declarations extraction tool for FFI interfaces.

Currently it only generates lua header files for LuaJIT FFI. That said, it
should be easy to add python cffi support.


Dependencies
------------

* Development headers for the toolchain on which you plan to use the plugin.

* Any Lua implementation compatible with Lua 5.1.


Building
--------

First fetch third party dependencies using `git submodule init` and
`git submodule update`.

THen just type `make` to build. The default setup builds the plugin
for an `arm-none-linux-gnueabi` toolchain located in `/opt/arm-2012.03`,
just like the default settings used by the koreader nightly build scripts.

However, the Makefile should autodetect and adapt to any toolchain given
the `CROSS_DIR` or `GCCPLUGIN_DIR` and the `CHOST` or `CROSSCC`/`CROSSCXX`
variables.

For example, if you are running an Ubuntu or Debian system and install the
`gcc-4.7-plugin-dev` package, you can build a plugin for you standard
`gcc` executable:

	make CROSS_DIR=/usr/lib/gcc CROSSCC=gcc CROSSCXX=g++

Also, if you install `gcc-4.7-arm-linux-gnueabi`, you can build a plugin
which can be used with that toolchain:

	make CROSS_DIR=/usr/lib/gcc CHOST=arm-linux-gnueabi

Read the Makefile for more details.


Usage
-----

See `test/` directory and [koreader-base][] for examples.

When you have the C file ready, run `ffi-cdecl gcc file.c output.lua` or
`ffi-cdecl g++ file.cpp output.lua` to generate a Lua file containing a
`ffi.cdef` declaring the desired functions, structs, etc.

When using a cross compiler, you need to replace `gcc` and `g++`
in these commands with the complete name of the compiler executable of your
toolchain, for example `arm-none-linux-gnueabi-gcc` or
`arm-none-linux-gnueabi-g++`.

You can also use `CPPFLAGS` environment variable to control build flags, for
example:

```
CPPFLAGS="-I. -LSDL2" ffi-cdecl gcc SDL2_0_decl.c SDL2_0_h.lua
```


[koreader-base]:https://github.com/koreader/koreader-base/tree/master/ffi-cdecl
