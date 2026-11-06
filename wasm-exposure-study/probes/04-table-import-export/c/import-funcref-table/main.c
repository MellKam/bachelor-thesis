typedef int (*__funcref fn_t)(int);
extern fn_t tbl[2] __attribute__((import_module("host"), import_name("tbl")));

static int twice(int x) { return x * 2; }
static int plus100(int x) { return x + 100; }

__attribute__((export_name("call_slot"))) int call_slot(int slot, int x) {
    __builtin_wasm_table_set(tbl, 0, (fn_t)twice);
    __builtin_wasm_table_set(tbl, 1, (fn_t)plus100);
    return __builtin_wasm_table_get(tbl, slot & 1)(x);
}
