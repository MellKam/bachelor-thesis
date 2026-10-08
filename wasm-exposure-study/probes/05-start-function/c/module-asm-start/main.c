static int g;
__attribute__((export_name("init"))) void init(void) { g = 7; }
__attribute__((export_name("get"))) int get(void) { return *(volatile int *)&g; }
