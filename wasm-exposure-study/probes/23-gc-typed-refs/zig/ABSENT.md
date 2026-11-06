# 23 gc typed refs — zig: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

Zig has no type that maps to a Wasm GC reference; its Wasm targets (`wasm32`, `wasm64` in `zig targets`) are linear-memory. No `-mcpu` feature or builtin for structs/arrays as GC objects was found in `zig build-exe --help` or the language reference. This is one level below Zig: LLVM's own WasmGC backend effort stalled from lack of funding (Paulo Matos/Igalia, LLVM discourse, Nov 2023: "our funding dried out and we ended up not being able to do it"). The LLVM backend Zig relies on has no struct/array GC-type support to surface, full stop.

Result: **Absent (confirmed)**.
