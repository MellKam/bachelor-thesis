# 28 Exception handling with exnref — MoonBit (wasm backend): no probe

Same finding as feature 27 (probe `raise`): MoonBit errors (`raise`, `try ... catch`) are ordinary control flow compiled to result checks; the module has no tag section and no `try_table` or `throw_ref`.

Result: **Absent (confirmed)**.

Checked on 2026-10-09: `moonc -test-mode` (set only by `moon test`, and not reachable from `moon.pkg.json`) builds a wasm-gc module that imports a host `exception.tag` and a `throw` function; it contains no `try_table`, no tag definition and no `throw` instruction. It is a host callback for panics in tests, not WebAssembly exception handling.
