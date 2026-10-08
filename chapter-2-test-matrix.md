# Chapter 2 — test matrix (plan)

Working plan for the experimental comparison in 2.4. Defines *what* is tested and in *which* languages. Cells are empty until
a probe has been run under the definitions below. Results from the earlier study (`wasm-exposure-study/`) must be re-coded
with the new vocabulary before they are carried over. The focus is on feature probes; the capstone programs (Game of Life,
WASI `cat`) are out of scope for now.

## Result vocabulary

A result says where a Wasm feature lives relative to the language, using two properties: is it **in the source**, and does the
**compiler understand it** (type-checks it)?

| Result | In source | Compiler understands | Meaning |
|---|---|---|---|
| Native | yes | yes | A language construct, or a typed standard-library / intrinsic function |
| Annotation | yes | yes | An attribute on an ordinary construct |
| Config | no | no | Build flag, config file or linker argument outside the source |
| Opaque | yes | no | Reached through inline assembly or Wasm text that the type system does not check |
| Absent | n/a | n/a | The language has no way to produce the feature (see modifiers) |

**Absent** carries one of two modifiers stating how sure we are:

- *Absent (confirmed)*: the documentation says there is no such construct, or the compiler / linker rejects the attempt.
- *Absent (not found)*: a construct plausibly exists, but no way to produce it was found. Weaker: one author, one pass.

**Notes are optional.** Most cells are just the result. Where the result only holds under a condition, a short flag after
it is enough: *partial* (e.g. memory limits settable but the name is fixed), *nightly only*, *opt-in flag*, *optimiser may
drop it*. A longer note is added only when a flag cannot say what was found. A feature the language is not expected to
express at all (e.g. GC in a linear-memory language) is still recorded as Absent, not skipped.

## Languages

Grouped by memory model. MoonBit has two backends that are different targets with different capabilities (25 of the 30 cells come out
the same on both). They share one column: each probe is run on both, a cell takes the better backend, and a feature that only one
backend has is marked "only on the `<backend>` backend" and counts it as one obstacle, because a module uses one backend
and cannot have both. C and C++ share a column for a different reason: one toolchain and target, and one module can mix them.

| Language | Group | Toolchain | Earlier study | Status |
|---|---|---|---|---|
| Rust | Linear memory, no runtime | rustc + `rust-lld`, `wasm32-unknown-unknown` | yes (1.99.0) | re-code |
| Zig | Linear memory, no runtime | Zig 0.16.0 | yes | re-code |
| C | Linear memory, no runtime | clang 23.1.0 + `wasm-ld` from wasi-sdk 34.0, `--target=wasm32-unknown-unknown` (Emscripten noted only as an ecosystem layer) | no | toolchain ready |
| MoonBit (`wasm` backend) | Linear memory, no runtime | `moon` 0.1.20260920 / `moonc` v0.10.14 | yes | re-code |
| AssemblyScript | Linear memory + runtime GC | `assemblyscript` 0.28.20 | yes | re-code |
| TinyGo | Linear memory + runtime GC | TinyGo 0.42.0 (Go 1.27.1) | no | toolchain ready |
| MoonBit (`wasm-gc` backend) | Wasm GC | same `moon` toolchain, `wasm-gc` target | no | toolchain ready (shared image); same column as the `wasm` backend |
| Kotlin/Wasm | Wasm GC | Kotlin 2.4.21 (`kotlinc-wasm`, JDK 25) | no | toolchain ready |

Dropped: Grain (not part of the comparison; its first-pass probes, results and toolchain were deleted from `wasm-exposure-study/`).

## Features

Only features that are part of a released version of the spec (`WebAssembly/proposals/finished-proposals.md`). The list is a single list in
stabilisation order: the module core (spec 1.0) first, then the 2.0 extensions, then the 3.0 extensions, the most recently standardised last.
Within a version the order follows when a feature was first available in a major engine; that within-version order is approximate and not yet
checked against the CG meeting notes. Features 4, 13, 16, 19, 21, 22, 24, 28 and 30 were added after the first 21 had been probed; they are
specified in `wasm-exposure-study/PROBES.md` and have since been probed in all eight columns.
A feature is either a piece of module structure (memory, globals, tags, ...) or a *family* of instructions probed as one unit.

| # | Spec | Feature |
|---|---|---|
| 1 | 1.0 | Imports and exports |
| 2 | 1.0 | Memory: limits, exported name, imported module and field |
| 3 | 1.0 | Table and indirect call |
| 4 | 1.0 | Table import and export |
| 5 | 1.0 | Start function |
| 6 | 1.0 | Data segments (placement of initialised data) |
| 7 | 1.0 | Custom sections |
| 8 | 1.0 | Integer operations (family) |
| 9 | 1.0 | Float builtins (family) |
| 10 | 1.0 | Globals (mutable; import and export) |
| 11 | 2.0 | Non-trapping conversions and sign extension (family) |
| 12 | 2.0 | Bulk memory (family) |
| 13 | 2.0 | Passive data segments |
| 14 | 2.0 | Multi-value results |
| 15 | 2.0 | SIMD (family) |
| 16 | 2.0 | SIMD memory and bitwise operations (family) |
| 17 | 2.0 | `externref` |
| 18 | 2.0 | Multiple tables |
| 19 | 2.0 | Table operations on references |
| 20 | 3.0 | Tail calls |
| 21 | 3.0 | Extended constant expressions |
| 22 | 3.0 | Typed function references |
| 23 | 3.0 | GC structs and arrays |
| 24 | 3.0 | GC casts, subtyping, i31, packed fields (family) |
| 25 | 3.0 | Multiple memories |
| 26 | 3.0 | Relaxed SIMD (family) |
| 27 | 3.0 | Exception tags |
| 28 | 3.0 | Exception handling with exnref |
| 29 | 3.0 | 64-bit memory |
| 30 | 3.0 | Branch hinting |

### Instruction families

| Feature | Members probed |
|---|---|
| Integer operations | add/sub/mul, div/rem, `clz`, `ctz`, `popcnt`, `rotl`/`rotr` |
| Float builtins | `sqrt`, `min`/`max`, `ceil`/`floor`/`trunc`/`nearest`, `copysign`, `abs` |
| Bulk memory | `memory.copy`, `memory.fill` |
| Non-trapping conversions and sign extension | `trunc_sat`, `extend8_s` / `extend16_s` |
| SIMD | lane arithmetic, splat / extract, one shuffle |
| Relaxed SIMD | e.g. relaxed multiply-add |
| SIMD memory and bitwise operations | `v128.load`, `v128.store`, `v128.bitselect`, `i8x16.narrow_i16x8_s` |
| GC casts, subtyping, i31, packed fields | declared subtype, `ref.test`/`ref.cast`, `ref.i31` + `i31.get`, packed `i8` array element |

**Cell rule for a family.** The matrix cell shows the *weakest member* on the order Native > Annotation > Opaque > Absent
(Config does not normally apply to an instruction). If members differ, the cell is marked *partial* with a note, and the
per-member results go in an appendix table. For each member, the appendix also records whether the instruction is
**guaranteed** to appear in the output or only survives when the optimiser leaves it alone.

### Left out on purpose

- Threads / atomics, wide arithmetic: phase 4, not part of any released spec version (stack switching and custom page sizes are phase 3).
- Deterministic profile: an execution-environment restriction, not something a language declares.
- Custom annotations: text format only, no effect on the binary.
- JS string builtins: specific to JS hosts, so it does not generalise across the languages compared.
- Table-specific bulk instructions (`table.copy`, `table.init`): not probed; feature 19 covers `table.get/set/grow/size` only.
- JS BigInt integration: a JS API, no effect on the module.

## Matrix

Each filled cell: the result, plus a short flag where needed (e.g. `Config, partial`). Longer notes, if any, are listed below
the matrix.

| # | Feature | Rust | Zig | C/C++ | MoonBit | AssemblyScript | TinyGo | Kotlin/Wasm |
|---|---|---|---|---|---|---|---|---|
| 1 | Imports and exports | | | | | | | |
| 2 | Memory: limits, exported name, imported module and field | | | | | | | |
| 3 | Table and indirect call | | | | | | | |
| 4 | Table import and export | | | | | | | |
| 5 | Start function | | | | | | | |
| 6 | Data segments (placement of initialised data) | | | | | | | |
| 7 | Custom sections | | | | | | | |
| 8 | Integer operations | | | | | | | |
| 9 | Float builtins | | | | | | | |
| 10 | Globals (mutable; import and export) | | | | | | | |
| 11 | Non-trapping conversions and sign extension | | | | | | | |
| 12 | Bulk memory | | | | | | | |
| 13 | Passive data segments | | | | | | | |
| 14 | Multi-value results | | | | | | | |
| 15 | SIMD | | | | | | | |
| 16 | SIMD memory and bitwise operations | | | | | | | |
| 17 | `externref` | | | | | | | |
| 18 | Multiple tables | | | | | | | |
| 19 | Table operations on references | | | | | | | |
| 20 | Tail calls | | | | | | | |
| 21 | Extended constant expressions | | | | | | | |
| 22 | Typed function references | | | | | | | |
| 23 | GC structs and arrays | | | | | | | |
| 24 | GC casts, subtyping, i31, packed fields | | | | | | | |
| 25 | Multiple memories | | | | | | | |
| 26 | Relaxed SIMD | | | | | | | |
| 27 | Exception tags | | | | | | | |
| 28 | Exception handling with exnref | | | | | | | |
| 29 | 64-bit memory | | | | | | | |
| 30 | Branch hinting | | | | | | | |

### Longer notes (only where a flag is not enough)

(none yet)

## Open points

- Re-pin the toolchain snapshot date: Rust, Zig, AssemblyScript and MoonBit were pinned on 2026-10-02; TinyGo, Kotlin and C on 2026-10-08.
- Emscripten as a second C column: undecided.
- Optional: cross-check the C results against the official LLVM release (wasi-sdk is a Wasm-only LLVM build at a different patch level).
- The ordering within a spec version is approximate. Before the chapter states it, check each proposal's phase-4 date against the CG
  meeting notes (the spec version of each feature is confirmed against `finished-proposals.md`; dates are not).
