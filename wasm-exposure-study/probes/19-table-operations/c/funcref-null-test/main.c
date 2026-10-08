typedef void (*__funcref fn_t)(void);
static fn_t tbl[0];

__attribute__((export_name("table_ops"))) int table_ops(int n) {
    __builtin_wasm_table_grow(tbl, __builtin_wasm_ref_null_func(), n + 1);
    return __builtin_wasm_table_get(tbl, 2) == __builtin_wasm_ref_null_func() ? 100 : 0; // the natural way to ask "is this slot empty"
}
