#include <wasm_simd128.h>

// The splatted operands go through memory, so the optimiser cannot turn extract(add(splat, splat)) back into a scalar add,
// and the result is used twice (stored, and one lane returned), so the lane extraction is not folded into the loads.
static volatile v128_t SA, SB, SC;

__attribute__((export_name("simd_add"))) int simd_add(int a, int b) {
    SA = wasm_i32x4_splat(a);
    SB = wasm_i32x4_splat(b);
    v128_t r = wasm_i32x4_add(SA, SB);
    SC = r;
    return wasm_i32x4_extract_lane(r, 0);
}

__attribute__((export_name("simd_shuffle"))) int simd_shuffle(int a, int b) {
    SA = wasm_i32x4_splat(a);
    SB = wasm_i32x4_splat(b);
    v128_t r = wasm_i8x16_shuffle(SA, SB, 16, 17, 18, 19, 4, 5, 6, 7, 24, 25, 26, 27, 12, 13, 14, 15);
    SC = r;
    return wasm_i32x4_extract_lane(r, 0);
}
