# 21 Extended constant expressions — TinyGo: no probe

Go package-level variables are linear-memory data, not Wasm globals (feature 10: `go-var`). Without a Wasm global to import or define, a global initialiser cannot combine one with arithmetic. A package-level `var g = base + 12` is a run-time initialiser, run by `_initialize`.

Result: **Absent (not found)**.
