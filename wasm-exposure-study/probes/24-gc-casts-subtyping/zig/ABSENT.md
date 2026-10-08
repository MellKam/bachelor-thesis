# 24 GC casts, subtyping, i31, packed fields — Zig: no probe

Same finding as feature 23 (see `../../23-gc-typed-refs/zig/ABSENT.md`): Zig's WebAssembly targets are linear-memory, structs and arrays
live there, and there is no builtin or syntax for GC types, casts or `i31`.

Result: **Absent (not found)**.
