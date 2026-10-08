# 19 Table operations on references — TinyGo: no probe

Function values use the single implicit indirect-call table (feature 03) and no Go construct, package or `//go:` directive operates on a table (`table.grow`, `table.get`, `table.set`, `table.size`, `ref.is_null`). The language has no reference types either (feature 17).

Result: **Absent (not found)**.
