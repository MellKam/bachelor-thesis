#define E(n) __attribute__((export_name(n)))
E("f_sqrt") double f_sqrt(double x) { return __builtin_sqrt(x); }
E("f_min") double f_min(double x, double y) { return __builtin_wasm_min_f64(x, y); }
E("f_max") double f_max(double x, double y) { return __builtin_wasm_max_f64(x, y); }
E("f_ceil") double f_ceil(double x) { return __builtin_ceil(x); }
E("f_floor") double f_floor(double x) { return __builtin_floor(x); }
E("f_trunc") double f_trunc(double x) { return __builtin_trunc(x); }
E("f_nearest") double f_nearest(double x) { return __builtin_roundeven(x); }
E("f_copysign") double f_copysign(double x, double y) { return __builtin_copysign(x, y); }
E("f_abs") double f_abs(double x) { return __builtin_fabs(x); }
