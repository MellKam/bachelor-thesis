# 17 externref — tinygo: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

The `wasm-unknown` target description disables the feature: `"features": "+nontrapping-fptoint,+sign-ext,-bulk-memory,-multivalue,-reference-types"` (`/opt/tinygo/targets/wasm-unknown.json`). Go has no externref type; `syscall/js` (the `wasm` target) uses imported functions, not reference types. tinygo-org/tinygo#2702 confirms the compiler cannot even accept a host externref parameter — it compiles the parameter as plain `i32` instead of rejecting or passing it through.

Result: **Absent (confirmed)**.
