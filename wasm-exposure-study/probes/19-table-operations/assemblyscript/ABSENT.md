# 19 Table operations on references — AssemblyScript: no probe

The only table builtins in AssemblyScript's declarations (`std/assembly/index.d.ts`, `declare namespace table`) are `table.init`,
`table.drop` and `table.copy`, which work on passive element segments; there is no `table.grow`, `table.get`, `table.set` or
`table.size`, and no `ref.is_null` for function references (`--enable reference-types` adds `externref` only). Function-typed
values live in one implicit table that the programmer cannot address. Binaryen has `table.get`/`set`/`size`/`grow` and `ref.is_null` as builder methods, but only reachable via the `afterCompile` transform hook on the already-compiled module (see `07-custom-sections/assemblyscript/ABSENT.md` for why that doesn't count as the language reaching it).

Result: **Absent (confirmed)**.
