#include "ansidecl.h"
int printf(const char *msg, ...);
int main() {
	printf("%d\n", GCC_VERSION);
	return 0;
}
