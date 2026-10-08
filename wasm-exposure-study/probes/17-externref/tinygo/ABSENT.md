# 17 externref — tinygo: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

The `wasm-unknown` target description disables the feature: `"features": "+nontrapping-fptoint,+sign-ext,-bulk-memory,-multivalue,-reference-types"` (`/opt/tinygo/targets/wasm-unknown.json`). Go has no externref type; `syscall/js` (the `wasm` target) uses imported functions, not reference types.

Result: **Absent (not found)**.
