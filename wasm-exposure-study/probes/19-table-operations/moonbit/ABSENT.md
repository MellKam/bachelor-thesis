# 19 Table operations on references — MoonBit (wasm backend): no probe

No MoonBit API operates on a table: no `table.grow`, `table.get`, `table.set`, `table.size` or `ref.is_null`. `#external` types (feature 17) are opaque host references that cannot be stored in an addressable table.

Result: **Absent (confirmed)**.
