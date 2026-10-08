# 19 Table operations on references — Kotlin/Wasm: no probe

No table exists in a Kotlin/Wasm module (feature 03) and no stdlib or `kotlin.wasm` API operates on one. `JsAny` is an `externref` (feature 17) but cannot be stored in a table the program can address.

Result: **Absent (not found)**.
