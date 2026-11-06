# I2 Component Model — Zig: Absent (confirmed)

Zig 0.16 has no component target (only wasm32-wasi, preview 1) and no WIT bindings generator; `wit-bindgen` has no Zig backend.
A component can be assembled by hand: `hand-abi-wasm-tools/` writes `cabi_realloc` and the lowered `analyse` in Zig, names the export
`study:words/words@0.1.0#analyse` and wraps the core module with `wasm-tools component embed` + `component new`. It passes the checker
(1266 bytes) but it is the developer doing the canonical ABI, not the language supporting components, so it is kept as evidence and not scored.
