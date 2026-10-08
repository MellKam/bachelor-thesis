static unsigned char buf[512];

__attribute__((export_name("bulk_test"))) unsigned bulk_test(unsigned n) {
    __builtin_memset(buf, 5, n);
    __asm__ volatile("" ::: "memory"); /* otherwise LLVM turns the copy of freshly memset bytes into a second memset */
    __builtin_memcpy(buf + 256, buf, n);
    unsigned s = 0;
    for (unsigned i = 0; i < n; i++) s += ((volatile unsigned char *)buf)[256 + i];
    return s;
}
