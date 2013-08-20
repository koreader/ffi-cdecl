ffi-cdecl
=========

I made these scripts trying to make the usage of gcc-lua-cdecl more comfortable.

Dependencies
------------

* Development headers for the toolchain on which you plan to use the plugin.

* Any Lua implementation compatible with Lua 5.1.

Building
--------

Just type `make` to build. The default setup builds the plugin 
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

* See the `test/` directory for examples.

* Run `ffi-cdecl gcc file.c` or `ffi-cdecl g++ file.cpp` to generate a
  Lua file on the standard output containing a `ffi.cdef` declaring
  the desired functions, structs, etc. When using a cross compiler,
   you need to replace `gcc` and `g++` in these commands with the complete
  name of the compiler executable of your toolchain, for example
  `arm-none-linux-gnueabi-gcc` or `arm-none-linux-gnueabi-g++`.

* If you want to output only the raw C declarations, without the Lua
  boilerplate, add the `-r` option. For example:
  `ffi-cdecl -r arm-none-linux-gnueabi-gcc file.c`

