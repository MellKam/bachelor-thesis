# 24 GC casts, subtyping, i31, packed fields — Zig: no probe

Same finding as feature 23 (see `../../23-gc-typed-refs/zig/ABSENT.md`): Zig's WebAssembly targets are linear-memory, structs and arrays
live there, and there is no builtin or syntax for GC types, casts or `i31`. Follows directly from 23's confirmed cause: the same
LLVM-level absence (no GC machine types, no struct/array/i31 lowering) applies identically here, since none of it exists without the
base GC-type infrastructure LLVM's backend doesn't have.

Result: **Absent (confirmed)**.
