# 28 Exception handling with exnref — TinyGo: no probe

Same finding as feature 27 (probe `panic-recover`): a Go `panic` traps and `recover` is implemented without exception tags, so the module has no tag section and no `try_table` or `throw_ref`. The merged implementation (tinygo-org/tinygo#5550) deliberately uses Asyncify-based unwinding instead of wasm exception-handling, specifically because many WASI runtimes don't yet support wasm-EH; an earlier wasm-EH-based attempt (#4380) was abandoned.

Result: **Absent (confirmed)**.
