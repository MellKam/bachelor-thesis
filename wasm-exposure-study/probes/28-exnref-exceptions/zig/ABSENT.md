# 28 Exception handling with exnref — Zig: no probe

Same finding as feature 27 (probe `error-union`): Zig has no exceptions; error unions and `try` are ordinary control flow and compile to
branches. Nothing in the language produces a tag, `try_table` or `throw_ref`, and the standard library has no unwinding support
on `wasm32-freestanding`.

Result: **Absent (not found)**.
