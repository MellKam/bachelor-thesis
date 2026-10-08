# 28 Exception handling with exnref — Zig: no probe

Same finding as feature 27 (probe `error-union`): Zig has no exceptions; error unions and `try` are ordinary control flow and compile to
branches. Nothing in the language produces a tag, `try_table` or `throw_ref`, and the standard library has no unwinding support
on `wasm32-freestanding`. LLVM's wasm backend does support `try_table`/`catch_ref`/`throw_ref`/exnref codegen (active upstream as of Jan
2025, llvm/llvm-project#124381), but only as a lowering target for `invoke`/`landingpad` IR — how C++ exceptions reach it. Zig's
error-union model never generates that IR for its own control flow, so there is no path from ordinary Zig code to this machinery.

Result: **Absent (confirmed)**.
