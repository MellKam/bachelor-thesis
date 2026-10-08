typedef int (*__funcref fn_t)(int);
static fn_t table_a[0];
static fn_t table_b[0];

static int add1(int x) { return x + 1; }
static int add100(int x) { return x + 100; }

__attribute__((export_name("call_a"))) int call_a(int x) {
    __builtin_wasm_table_grow(table_a, (fn_t)add1, 1);
    return __builtin_wasm_table_get(table_a, 0)(x);
}

__attribute__((export_name("call_b"))) int call_b(int x) {
    __builtin_wasm_table_grow(table_b, (fn_t)add100, 1);
    return __builtin_wasm_table_get(table_b, 0)(x);
}
