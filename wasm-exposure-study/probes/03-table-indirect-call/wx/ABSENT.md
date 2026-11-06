# 03-table-indirect-call — WX: Absent (confirmed)

WX has no table declaration, no element segments and no `call_indirect`. A `func(A) -> R` value lowers to `call_ref` in the design, which needs typed function references; neither tables nor that lowering exist in the current compiler (tables are designed, not implemented: notes in the repository).

**Status:** Not implemented yet. Tables are designed but not built; every kind of function reference depends on them. Absent in the current compiler, not ruled out by the language design.
