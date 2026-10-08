# 24 GC casts, subtyping, i31, packed fields — C/C++: no probe

Same finding as feature 23 (see `../../23-gc-typed-refs/c/ABSENT.md`): clang's WebAssembly target is linear-memory. Structs and arrays
in C and C++ live in linear memory, `__externref_t` and `__funcref` are opaque and cannot be cast or subtyped, and there are no
builtins for `struct.new`, `ref.cast`, `ref.i31` or packed arrays. The assembler accepts `+gc` instructions such as `call_ref`
(feature 22) but has no syntax for declaring GC types.

Result: **Absent (not found)**.
