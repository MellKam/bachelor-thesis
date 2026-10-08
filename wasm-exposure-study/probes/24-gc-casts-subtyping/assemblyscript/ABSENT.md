# 24 GC casts, subtyping, i31, packed fields — AssemblyScript: no probe

Same finding as feature 23 (probe `classes-enable-gc`): `--enable gc` is documented as work in progress and the classes stay in linear
memory with or without it, so there are no GC struct types to cast, subtype or pack.

Result: **Absent (not found)**.
