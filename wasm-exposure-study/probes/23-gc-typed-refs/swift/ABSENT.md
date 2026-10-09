# 23 gc typed refs — Swift: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

Swift's Wasm targets (`wasm32-unknown-wasip1`, `wasm32-unknown-none-wasm` and `wasm64-unknown-none-wasm` in the 6.4.0 SDK and
toolchain) are linear-memory: classes are reference-counted heap objects in linear memory, structs are value types laid out in memory.
The compiler's feature list for the target (`+bulk-memory`, `+multivalue`, `+mutable-globals`, `+nontrapping-fptoint`, `+reference-types`,
`+sign-ext`; `simd128`, `relaxed-simd` and `tail-call` opt-in) has no `gc`, and no attribute or `Builtin` intrinsic constructs a struct or
array type. This is one level below Swift: LLVM's own WasmGC backend effort stalled for lack of funding (Paulo Matos/Igalia, LLVM
discourse, Nov 2023), and Swift reaches Wasm through LLVM.

Result: **Absent (confirmed)**.
