# 23 gc typed refs — c: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

clang exposes `__externref_t` and `__funcref` (reference types) but no struct or array reference types; the LLVM WebAssembly backend has a `gc` feature flag (`-mgc` is accepted) that only permits instruction selection. No C construct produces a GC struct or array. LLVM's own WasmGC backend effort stalled from lack of funding (Paulo Matos/Igalia, LLVM discourse, Nov 2023: "our funding dried out and we ended up not being able to do it") after only externref/funcref landed — still true even though Wasm 3.0 shipped (Sept 2025) with GC structs/arrays as a core feature. C's type system also has no notion of a managed/traced reference distinct from a raw pointer.

Result: **Absent (confirmed)**.
