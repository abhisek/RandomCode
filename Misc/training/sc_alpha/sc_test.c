#include <stdio.h>
#include <sys/mman.h>
#include <assert.h>

const char shellcode[] = { 
	"\xcc\xcc\xcc"
};

main()
{
	void (*f)();
	void *p = mmap(NULL, sizeof(shellcode) + 1, PROT_READ | PROT_WRITE | PROT_EXEC,
		MAP_ANON | MAP_PRIVATE, -1, 0);

	assert(p != NULL);
	f = (void*) shellcode;
	f();
}
