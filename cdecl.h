#ifndef cdecl_func
#define cdecl_func(name) __typeof__(name) *cdecl_func__ ## name = &name;
#define cdecl_var cdecl_func
#define cdecl_type(name) name *cdecl_type__ ## name;
#define cdecl_struct(name) struct name *cdecl_struct__ ## name;
#define cdecl_const(name) __typeof__(name) cdecl_const__ ## name = name;
#endif
