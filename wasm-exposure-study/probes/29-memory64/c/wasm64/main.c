__attribute__((export_name("touch"))) int touch(void) {
    volatile int *p = (volatile int *)16;
    *p = 42;
    return *p;
}
