// clang's address space 1 means "a Wasm global" on this target
__attribute__((address_space(1))) int counter;
extern __attribute__((address_space(1))) const int base;

__attribute__((export_name("bump"))) int bump(void) { counter = base + 1; return counter; }
