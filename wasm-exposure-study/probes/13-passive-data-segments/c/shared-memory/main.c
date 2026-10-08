static const unsigned char DATA[4] = { 'W', 'A', 'S', 'M' };

__attribute__((export_name("load"))) void load(int dst) {
    const unsigned char *volatile src = DATA; // keeps the copy from being folded into immediate stores
    __builtin_memcpy((void *)dst, (const void *)src, 4);
}

__attribute__((export_name("peek"))) int peek(int addr) { return *(volatile unsigned char *)addr; }
