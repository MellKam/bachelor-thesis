# 24 GC casts, subtyping, i31, packed fields — TinyGo: no probe

Same finding as feature 23 (probe `struct-slice`): TinyGo's garbage collector manages linear memory, Go structs and slices are plain memory, and the compiler emits no Wasm GC types, casts, `i31` or packed arrays.

Result: **Absent (not found)**.
