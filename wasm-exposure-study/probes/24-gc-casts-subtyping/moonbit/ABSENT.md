# 24 GC casts, subtyping, i31, packed fields — MoonBit (wasm backend): no probe

Same finding as feature 23 (probe `struct-array`, "wasm-gc backend only"): on the `wasm` backend structs, enums and arrays live in linear memory, so there are no GC types to cast, subtype or pack. The wasm-gc backend is the other column.

Result: **Absent (not found)**.
