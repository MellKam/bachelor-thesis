# 21 Extended constant expressions — MoonBit (wasm-gc backend): no probe

A MoonBit top-level `let` is not a Wasm global the program can import or give an initialiser expression (feature 10): it is initialised by code, in the module's start function.

Result: **Absent (not found)**.
