# 24 GC casts, subtyping, i31, packed fields — TinyGo: no probe

Same finding as feature 23 (probe `struct-slice`): TinyGo's garbage collector manages linear memory, Go structs and slices are plain memory, and the compiler emits no Wasm GC types, casts, `i31` or packed arrays. LLVM's wasm backend itself has no struct.new/array.new codegen path at all — WasmGC codegen exists only in non-LLVM toolchains — so there is nothing to cast, subtype or pack as a follow-on.

Result: **Absent (confirmed)**.
