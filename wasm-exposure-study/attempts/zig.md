# Zig — probe results

Toolchain: Zig 0.16.0, target `wasm32-freestanding`, image `wasm-exposure-zig`. Build command (in each variant's `cmd` file):
`zig build-exe main.zig -target wasm32-freestanding -fno-entry -rdynamic -O ReleaseSmall -femit-bin=out.wasm` plus probe-specific flags.
`ReleaseSmall` is the release mode used for sizes (P12 also reports `ReleaseFast`). `-rdynamic` was used to export the `export fn`s;
whether exports survive without it was not tested. Run all with `sh probes/run-zig.sh`; logs in `results/zig/`, sources in
`probes/<id>/zig/<variant>/`. Codes: README §6. No nightly/unstable toolchain was used.

| Probe | Result | One-line summary |
|---|---|---|
| P1 imports/exports | **N** | `extern "host" fn log(i32) void;` names the import module in the language's own `extern` syntax; `export fn` exports |
| P2 memory export | **C\*** partial | limits via flags; exported name is fixed to `memory` |
| P2 memory import | **C\*** partial | limits via flags; import is fixed to `env.memory` |
| P3 multi-memory | **X** | `@wasmMemorySize(1)` is accepted but the module has one memory, so it is invalid |
| P4 globals | **X** | variables live in linear memory; the "global" export is an address |
| P5 table + indirect call | **N** (call), table implicit | function pointers → table + element segment + `call_indirect` |
| P6 multi-value | **X** | struct return uses an out-pointer |
| P7 start function | **A\*** partial | `linksection(".init_array")` constructor; no start section |
| P8 externref | **X** | no reference-type in the language; a pointer is an `i32` |
| P9 exceptions | **X** | Zig errors are values; no tags or `try`/`catch` instructions |
| P10 raw instructions | popcnt **N**, SIMD **N** + **C** | `@popCount`; `@Vector` lowers to `i32x4.add` once `-mcpu=generic+simd128` is set |
| P11 custom section | **X** | `linksection` put the bytes in the data section; no custom section appeared |
| P12 baseline | measured | ReleaseSmall: 73 bytes; ReleaseFast: 4,977 bytes |

## What differs from the reference modules

- **P2.** `zig build-exe --help` documents `--import-memory`, `--export-memory`, `--initial-memory`, `--max-memory`, `--stack`, `--export-table`,
  `--import-table`; none takes a name. With those flags the limits (1..4 pages) were met, but the memory exports as `memory` and
  imports as `env.memory`, so the reference's `mem` and `host.mem` are unreachable. Zig also has `@wasmMemorySize(i)` /
  `@wasmMemoryGrow(i, n)` builtins that take a memory index, but nothing to declare a memory in source.
- **P3.** `@wasmMemorySize(1)` compiles, but the output is **an invalid module** (`memory variable out of range: 1 (max 1)`): the
  builtin accepts an index while the linker produces exactly one memory. Same failure shape as Rust's nightly assembly attempt.
- **P4.** `extern "host" const base: i32` is a *data* symbol, not a global import: the build fails (`wasm-ld: undefined symbol: base`),
  and with `--import-symbols` it links but there is no `host.base` import. `export var counter` appears as an exported **immutable**
  global whose value is the variable's *address* (1048576), not a mutable `i32` global. So `bump()` returned 1, not 42.
- **P5.** The table is implicit. The array of function pointers must be `var` (not `const`) to keep the lookup indirect.
- **P6.** Returning an `extern struct` compiles to `(i32, i32, i32) -> ()` (out-pointer); calling it with two arguments hit a divide by zero in
  the callee. Zig's C calling convention is what decides this.
- **P7.** No start section. A constructor in `.init_array` yields a wrapper around `get` that runs the initialiser first (the same
  mechanism as Rust's `command_export` thunk); `get()` returned 7. Whether the constructor is guarded against re-running was not tested.
- **P8.** `?*anyopaque` is a plain `i32`, so `identity` has type `(i32) -> (i32)`.
- **P9.** `error{Boom}!i32` with `catch` compiles to ordinary control flow; the module has no tag section.
- **P10.** The first version (splat + splat, then lane 0) produced no `i32x4.add`; only after routing the operands and result through
  `volatile` pointers did `i32x4.add` appear. That is the same effect seen in Rust (the optimiser folds splat-add into a scalar add);
  the Zig output for the folded version was not inspected, so I am not attributing it to a specific backend.
- **P11.** Tried `linksection(".custom_section.meta")` (default linker and `-flld`) and `linksection("meta")`. All three placed the bytes in
  the data section and emitted no custom section. Only these three forms were tried.
- **P12.** Surplus in ReleaseSmall: exported `memory`, a 16-page memory (default stack), one table, one global (stack pointer), no
  imports. ReleaseFast is larger only because it keeps DWARF debug sections.

## Compilation route

The P4 build error names `wasm-ld` as the failing linker, so at least in that configuration Zig emits an object file and links with
LLD (like Rust). Whether Zig's other backends/linker are used elsewhere was not checked.
