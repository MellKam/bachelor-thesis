__asm__(".section .custom_section.meta,\"\",@\n.ascii \"hello\"\n");

__attribute__((export_name("nop"))) void nop(void) {}
