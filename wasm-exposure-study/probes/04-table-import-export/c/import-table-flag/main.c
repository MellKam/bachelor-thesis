static int twice(int x) { return x * 2; }
static int plus100(int x) { return x + 100; }
int (*slots[2])(int) = { twice, plus100 };

__attribute__((export_name("call_slot"))) int call_slot(int slot, int x) { return slots[slot & 1](x); }
