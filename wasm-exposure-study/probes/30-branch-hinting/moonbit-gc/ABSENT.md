# 30 Branch hinting — MoonBit (wasm-gc backend): no probe

MoonBit has no `likely`/`unlikely` construct or attribute, and `moonc` has no option that emits the `metadata.code.branch_hint` section.

Result: **Absent (not found)**.
