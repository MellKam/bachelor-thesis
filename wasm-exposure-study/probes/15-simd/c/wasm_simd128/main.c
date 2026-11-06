#include <wasm_simd128.h>

__attribute__((export_name("simd_add"))) int simd_add(int a, int b) {
    return wasm_i32x4_extract_lane(wasm_i32x4_add(wasm_i32x4_splat(a), wasm_i32x4_splat(b)), 0);
}

__attribute__((export_name("simd_shuffle"))) int simd_shuffle(int a, int b) {
    v128_t r = wasm_i32x4_shuffle(wasm_i32x4_splat(a), wasm_i32x4_splat(b), 4, 1, 6, 3);
    return wasm_i32x4_extract_lane(r, 0);
}
