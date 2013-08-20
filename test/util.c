#define _BSD_SOURCE
#include <unistd.h>
#include <sys/statvfs.h>
#include <sys/time.h>
#include "cdecl.h"

cdecl_struct(timeval)
cdecl_func(gettimeofday)
cdecl_func(sleep)
cdecl_func(usleep)
cdecl_struct(statvfs)
cdecl_func(statvfs)
