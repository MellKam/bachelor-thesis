# 24 GC casts, subtyping, i31, packed fields — AssemblyScript: no probe

Same finding as feature 23 (probe `classes-enable-gc`): `--enable gc` is documented as work in progress and the classes stay in linear
memory with or without it, so there are no GC struct types to cast, subtype or pack. The same `afterCompile`/Binaryen caveat noted for feature 07 applies identically (see
`07-custom-sections/assemblyscript/ABSENT.md`): Binaryen's TypeBuilder/struct.*/array.* API is reachable only via that transform
hook on the already-compiled module, not something AssemblyScript itself produces.

Result: **Absent (confirmed)**.
