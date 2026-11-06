# 16 SIMD memory and bitwise operations — TinyGo: no probe

No SIMD at all: see feature 15. TinyGo's `wasm-unknown` target does not enable `simd128`, Go has no vector types, and no package exposes `v128` operations, so there is nothing to write `v128.load`, `v128.bitselect` or `i8x16.narrow_i16x8_s` with.

Result: **Absent (not found)**.
