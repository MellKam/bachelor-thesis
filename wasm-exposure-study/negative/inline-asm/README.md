# Is any inline-assembly route checked by the language's compiler?

`checked` (results/README.md) is true for an `inline_asm` cell only if the language's own compiler relates the hand-written block to the
surrounding program: a typed operand, or a signature compared with the body. Every `inline_asm` cell was coded unchecked by default; these
negative probes test that instead of assuming it. Each case is a program whose assembly or Wasm text disagrees with the source around it.
`out.wasm` is what the toolchain produced; `wasm-tools validate` says whether it is a valid module. Run a case with its `cmd` in the
language's container (`make c-shell` etc.), from the case directory.

| Language | Route | Case | What the compiler did | Module |
|---|---|---|---|---|
| Rust (nightly) | `global_asm!` | `body-type-error` (`i32.add` with one operand) | built | **invalid** |
| Rust (nightly) | `global_asm!` | `signature-mismatch` (declared `fn bump(i32) -> i32`, assembly `() -> i32`) | built | valid, mismatch not noticed |
| Zig | module-level `asm` | `body-type-error` | built | **invalid** |
| Zig | module-level `asm` | `signature-mismatch` | built | valid, mismatch not noticed |
| C | module-level `__asm__` | `body-type-error` | built | **invalid** |
| C | module-level `__asm__` | `signature-mismatch` | built | valid, mismatch not noticed |
| MoonBit, wasm and wasm-gc | `extern "wasm"` | `arity-mismatch` (MoonBit `(Int) -> Int`, text takes two parameters) | built | **invalid** |
| MoonBit, wasm and wasm-gc | `extern "wasm"` | `body-type-error` (`f32.neg` on an i32) | built | **invalid** |
| MoonBit, wasm and wasm-gc | `extern "wasm"` | `result-mismatch` (text returns an i64) | built | **invalid** |

Conclusion: none of the four routes is checked. The compilers accept an ill-typed body and write an invalid module; the first error
would be reported by the engine at load time. So no cell carries `checked: true`, and the Checked count has no inline-assembly part.

Two details worth knowing:
- Function-level assembly with typed operands (Rust `asm!`, Zig `asm` with inputs and outputs, C `__asm__` with constraints) is where a
  compiler does relate the block to the program. None of the coded cells uses it: every one of them needs a Wasm module-level construct
  (a global, a table, a tag, a typed `ref.func`, a start section) that function-level assembly cannot declare. That, not oversight, is why
  there is nothing to mark checked.
- An earlier C run of case `body-type-error` failed with a Binaryen parse error. That came from `clang` running `wasm-opt` after linking,
  because the base image had put Binaryen on `PATH`; it was not the compiler. Binaryen is now addressed only through `WASM_OPT`.
