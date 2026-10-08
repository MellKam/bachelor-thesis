# 18 multiple tables — tinygo: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

Function values use the single indirect-call table (feature 03). No Go construct declares a table. A second table would need the reference-types proposal, which the `wasm-unknown` target explicitly disables (`-reference-types`).

Result: **Absent (confirmed)**.
