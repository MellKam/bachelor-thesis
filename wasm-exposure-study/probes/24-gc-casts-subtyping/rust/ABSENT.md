# 24 GC casts, subtyping, i31, packed fields — Rust: no probe

Same finding as feature 23 (see `../../23-gc-typed-refs/rust/ABSENT.md`): every Rust Wasm target is linear-memory, `core::arch::wasm32`
has no reference types for structs, arrays or `i31`, and the LLVM assembler has no syntax for declaring GC types or for the cast
instructions. `-C target-feature=+gc` only permits LLVM to select such instructions; no Rust construct produces them. Follows directly from
feature 23 (confirmed absent): no struct/array/i31 GC-type infrastructure exists in LLVM's wasm backend to build casts, subtyping
or packed-field access on top of.

Result: **Absent (confirmed)**.
