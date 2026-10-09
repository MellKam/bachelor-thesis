# I2 Component Model — MoonBit, wasm-gc backend: Absent (confirmed)

`wit-bindgen moonbit` generates bindings for the linear-memory `wasm` backend (strings and records go through linear memory and
`cabi_realloc`); a wasm-gc module has no linear memory (see I1), so the canonical ABI has nothing to lower into.
