# 28 Exception handling with exnref — TinyGo: no probe

Same finding as feature 27 (probe `panic-recover`): a Go `panic` traps and `recover` is implemented without exception tags, so the module has no tag section and no `try_table` or `throw_ref`.

Result: **Absent (not found)**.
