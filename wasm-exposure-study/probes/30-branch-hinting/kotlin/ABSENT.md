# 30 Branch hinting — Kotlin/Wasm: no probe

Kotlin has no `likely`/`unlikely` construct and `kotlinc-wasm` has no option that emits the `metadata.code.branch_hint` section (`kotlinc-wasm -X` lists only `-Xwasm-*` options for debug info, array checks, exceptions, stack switching, the target and incremental compilation).

Result: **Absent (not found)**.
