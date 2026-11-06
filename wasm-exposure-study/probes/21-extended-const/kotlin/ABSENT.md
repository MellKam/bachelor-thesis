# 21 Extended constant expressions — Kotlin/Wasm: no probe

Kotlin top-level properties are not Wasm globals the program can import or give an initialiser (feature 10: `top-level-var`); they are initialised by `_initializeModule`, a start function.

Result: **Absent (not found)**.
