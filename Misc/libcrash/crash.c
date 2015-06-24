#include <stdio.h>

void __attribute__ ((constructor)) crash_init(void);

static
void do_crash()
{
	__asm(
		"movl $0x00, %eax\n"
		"jmp *%eax"
	);
}

void crash_init()
{
	atexit(&do_crash);	
}
