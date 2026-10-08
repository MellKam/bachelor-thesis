# 23 gc typed refs — c: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

clang exposes `__externref_t` and `__funcref` (reference types) but no struct or array reference types; the LLVM WebAssembly backend has a `gc` feature flag (`-mgc` is accepted) that only permits instruction selection. No C construct produces a GC struct or array.

Result: **Absent (not found)**.
