#include <features.h>
#if defined(__UCLIBC__)
LIBC=uclibc
#elif defined(__dietlibc__)
LIBC=dietlibc
#else
LIBC=gnu
#endif
