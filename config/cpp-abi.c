#include <stdio.h>
int plugin_is_GPL_compatible;
int _Z14get_identifierPKc(char const*);
int plugin_init() {
	printf("cpp-abi-ok: %p\n", _Z14get_identifierPKc);
	return 0;
}
