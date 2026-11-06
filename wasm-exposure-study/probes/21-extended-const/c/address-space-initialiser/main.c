// the natural attempt: a Wasm global (address space 1) initialised from another global plus arithmetic
extern __attribute__((address_space(1))) const int base;
__attribute__((address_space(1))) const int g = base + 4 * 3;

__attribute__((export_name("get_g"))) int get_g(void) { return g; }
