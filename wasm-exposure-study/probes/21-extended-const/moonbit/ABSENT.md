# 21 Extended constant expressions — MoonBit (wasm backend): no probe

A MoonBit top-level `let` is not a Wasm global the program can import or give an initialiser expression (feature 10): it is initialised by code, in the module's start function. Confirmed more broadly: there is no global-import mechanism at all in MoonBit (FFI only imports functions and memory), so there is no global for a const-expr initializer to even target.

Result: **Absent (confirmed)**.
