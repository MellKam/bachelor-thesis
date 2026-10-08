# 28 Exception handling with exnref — MoonBit (wasm-gc backend): no probe

Same finding as feature 27 (probe `raise`): MoonBit errors (`raise`, `try ... catch`) are ordinary control flow compiled to result checks; the module has no tag section and no `try_table` or `throw_ref`.

Lead, untested: moonc's wasm-gc codegen (`wasm_of_clam_gc.ml`) has a real `Lcatch` IR node lowering to `try_table`/`catch` with an imported tag and `$throw`, gated by `assert !Basic_config.test_mode` — a flag `moon test` sets. This looks like the test harness's own panic-catching mechanism, not something `raise`/`try...catch` reaches, and whether it specifically exercises exnref/throw_ref semantics needs inspection of an actual `-test-mode` build. No equivalent code exists on the plain wasm backend.

Result: **Absent (not found)**.
