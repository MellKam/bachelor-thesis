# 22-typed-function-references — WX: Absent (confirmed)

No `ref.func` or `call_ref` is emitted by the current backend: `func(A) -> R` calls are specified to lower to `call_ref` but this path is not lowered yet.

**Status:** Not implemented yet; depends on tables and function references. Absent in the current compiler, not ruled out by the language design.
