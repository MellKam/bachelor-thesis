#include <wasm_simd128.h>

static int A[4], B[4], C[4];

/* Vectors come from and go to memory, so LLVM cannot scalarise the lane operation away. */
static int run(int a, int b, int shuffle) {
    for (int i = 0; i < 4; i++) { ((volatile int *)A)[i] = a; ((volatile int *)B)[i] = b; }
    v128_t va = wasm_v128_load(A), vb = wasm_v128_load(B);
    v128_t r = shuffle ? wasm_i32x4_shuffle(va, vb, 4, 1, 6, 3) : wasm_i32x4_add(va, vb);
    wasm_v128_store(C, r);
    return ((volatile int *)C)[0];
}

__attribute__((export_name("simd_add"))) int simd_add(int a, int b) { return run(a, b, 0); }
__attribute__((export_name("simd_shuffle"))) int simd_shuffle(int a, int b) { return run(a, b, 1); }
