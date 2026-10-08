#include <wasm_simd128.h>

__attribute__((export_name("relaxed_madd"))) float relaxed_madd(float a, float b, float c) {
    return wasm_f32x4_extract_lane(wasm_f32x4_relaxed_madd(wasm_f32x4_splat(a), wasm_f32x4_splat(b), wasm_f32x4_splat(c)), 0);
}
