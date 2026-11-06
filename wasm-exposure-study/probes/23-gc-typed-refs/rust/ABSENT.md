# 23 GC and typed references — Rust: no probe

No program was written, because there is nothing in the language to write it with. What was checked, inside `wasm-exposure-rust`
(rustc 1.99.0 and `nightly-2026-10-02`):

```
$ rustc --print target-list | grep -i wasm
wasm32-unknown-emscripten  wasm32-unknown-unknown  wasm32-wali-linux-musl  wasm32-wasip1  wasm32-wasip1-threads
wasm32-wasip2  wasm32-wasip3  wasm32v1-none  wasm64-unknown-unknown
$ rustc --print target-features --target wasm32-unknown-unknown | grep -iE "gc|multimemory"
    gc          - Enable wasm gc.
    multimemory - Enable multiple memories.
```

Every Rust Wasm target is linear-memory. The compiler does accept `-C target-feature=+gc`, but that only allows LLVM to select
those instructions; `core::arch::wasm32` has no struct or array reference types and Rust's own types (`Box`, `Vec`, structs) always
live in linear memory. Assembly cannot declare a GC struct type (the LLVM assembler has no syntax for it).

rust-lang/rust#150111 (merged) adds `target_feature = "gc"` only as a detection flag for tools like wasm-bindgen; its author states
explicitly that these features are "not accessible through Rust apart from unstable inline ASM," which has no GC-type declaration
syntax. The root cause is one level below Rust: LLVM's own WasmGC backend effort stalled from lack of funding (Paulo Matos/Igalia,
LLVM discourse, Nov 2023: "our funding dried out and we ended up not being able to do it") — the identical gap already confirmed for
Zig and TinyGo in this study, since all three share the same LLVM wasm backend.

Result: **Absent (confirmed)**.
