__attribute__((section(".custom_section.meta"), used)) const char meta[5] = {'h', 'e', 'l', 'l', 'o'};

__attribute__((export_name("nop"))) void nop(void) {}
