# 19 Table operations on references — AssemblyScript: no probe

The only table builtins in AssemblyScript's declarations (`std/assembly/index.d.ts`, `declare namespace table`) are `table.init`,
`table.drop` and `table.copy`, which work on passive element segments; there is no `table.grow`, `table.get`, `table.set` or
`table.size`, and no `ref.is_null` for function references (`--enable reference-types` adds `externref` only). Function-typed
values live in one implicit table that the programmer cannot address.

Result: **Absent (not found)**.
