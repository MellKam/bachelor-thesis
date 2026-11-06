# I2 Component Model — Kotlin: Absent (confirmed)

Kotlin/Wasm has only the `wasm-wasi` (preview 1) and `wasm-js` targets and no WIT generator. `hand-abi-wasm-tools/` writes the canonical
ABI by hand (`@WasmExport("study:words/words@0.1.0#analyse")`, `cabi_realloc` over the unsafe memory API) and wraps the module with
`wasm-tools component new --adapt` and the WASI preview-1 reactor adapter: it passes the checker (623 KB; the GC module and its runtime
survive componentisation). It is the developer doing the ABI, not support, so it is evidence and not scored.
