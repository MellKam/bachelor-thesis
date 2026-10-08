# 23 gc typed refs — zig: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

Zig has no type that maps to a Wasm GC reference; its Wasm targets (`wasm32`, `wasm64` in `zig targets`) are linear-memory. No `-mcpu` feature or builtin for structs/arrays as GC objects was found in `zig build-exe --help` or the language reference.

Result: **Absent (not found)**.
