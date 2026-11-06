#include <wasm_simd128.h>

// Vectors come from and go to linear memory, so the optimiser cannot fold them into scalar code.
__attribute__((export_name("v_copy"))) int v_copy(int p) {
    unsigned char *q = (unsigned char *)p;
    wasm_v128_store(q + 16, wasm_v128_load(q));
    return *(volatile unsigned char *)(q + 16);
}

__attribute__((export_name("v_select"))) int v_select(int p) {
    unsigned char *q = (unsigned char *)p;
    v128_t r = wasm_v128_bitselect(wasm_v128_load(q), wasm_v128_load(q + 16), wasm_v128_load(q + 32));
    wasm_v128_store(q + 48, r);
    return wasm_i32x4_extract_lane(r, 0);
}

__attribute__((export_name("v_narrow"))) int v_narrow(int p) {
    unsigned char *q = (unsigned char *)p;
    wasm_v128_store(q + 32, wasm_i8x16_narrow_i16x8(wasm_v128_load(q), wasm_v128_load(q + 16)));
    return *(volatile unsigned char *)(q + 39);
}
