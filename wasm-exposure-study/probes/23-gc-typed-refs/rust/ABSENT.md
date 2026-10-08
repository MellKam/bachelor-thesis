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

Result: **Absent (not found)**. No documentation statement or compiler rejection was found to make it *confirmed*.
