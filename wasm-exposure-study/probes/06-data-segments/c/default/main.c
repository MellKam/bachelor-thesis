__attribute__((used)) const char DATA[4] = {'W', 'A', 'S', 'M'};
__attribute__((export_name("peek"))) int peek(unsigned addr) { return *(volatile unsigned char *)addr; }
