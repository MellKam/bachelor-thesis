#define E(n) __attribute__((export_name(n)))
E("sat_trunc") int sat_trunc(double x) { return __builtin_wasm_trunc_saturate_s_i32_f64(x); }
E("ext8") int ext8(int x) { return (signed char)x; }
E("ext16") int ext16(int x) { return (short)x; }
