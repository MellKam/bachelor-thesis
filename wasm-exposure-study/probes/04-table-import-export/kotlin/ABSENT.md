# 04 Table import and export — Kotlin/Wasm: no probe

The module has no funcref table at all: Kotlin/Wasm calls function values with `call_ref` on GC closure objects (feature 03, probe `function-values`), so there is no table to export or import, and no compiler option or annotation declares one.

Result: **Absent (not found)**.
