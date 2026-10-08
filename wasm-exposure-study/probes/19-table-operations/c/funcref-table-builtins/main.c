typedef void (*__funcref fn_t)(void);
static fn_t tbl[0];

static void f(void) {}

// clang offers table.grow/set/get/size for funcref tables but no way to test a funcref for null (comparing one crashes the
// backend: "Cannot select: setcc funcref"), so the null checks of the task cannot be written; the rest is.
__attribute__((export_name("table_ops"))) int table_ops(int n) {
    __builtin_wasm_table_grow(tbl, __builtin_wasm_ref_null_func(), n + 1);
    __builtin_wasm_table_set(tbl, 1, (fn_t)f);
    fn_t g = __builtin_wasm_table_get(tbl, 1);
    g();
    return __builtin_wasm_table_size(tbl);
}
