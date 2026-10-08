# 28 Exception handling with exnref — MoonBit (wasm backend): no probe

Same finding as feature 27 (probe `raise`): MoonBit errors (`raise`, `try ... catch`) are ordinary control flow compiled to result checks; the module has no tag section and no `try_table` or `throw_ref`.

Result: **Absent (not found)**.
