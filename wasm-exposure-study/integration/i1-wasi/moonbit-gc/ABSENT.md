# I1 WASI — MoonBit, wasm-gc backend: Absent (confirmed)

The WASI preview-1 `cat` needs `fd_read` and `fd_write`, which pass an iovec in linear memory and require the module to export
that memory. A wasm-gc MoonBit module has no linear memory at all (the same reason features 06 and 13, data segments, are
only reachable on the `wasm` backend), and MoonBit's standard library has no WASI binding on either backend (`core` has no
stdin; `println` calls a host import). A WASI component would need the canonical ABI with GC types, which no toolchain here emits.
Not attempted as a build: there is no source that could pass the iovec.
