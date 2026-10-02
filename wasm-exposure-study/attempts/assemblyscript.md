# AssemblyScript — probe results

Toolchain: `asc` 0.28.20 (Binaryen 131.0.0-nightly.20260721 via the lockfile), image `wasm-exposure-assemblyscript`.
Release build, as documented in `asc --help` ("Make a release build: `-O --noAssert`"):
`asc main.ts -o out.wasm -O --noAssert` plus probe-specific flags. Run all with `sh probes/run-assemblyscript.sh`; logs in
`results/assemblyscript/`, sources in `probes/<id>/assemblyscript/<variant>/`. Codes: README §6. Stable release only.

| Probe | Result | One-line summary |
|---|---|---|
| P1 imports/exports | **A** | `@external("host", "log") declare function`; `export function` |
| P2 memory export | **C\*** partial | limits via `--initialMemory/--maximumMemory`; name fixed to `memory` |
| P2 memory import | **C\*** partial | `--importMemory`; import fixed to `env.memory` |
| P3 multi-memory | **X** | `memory.size()` takes no argument; no multi-memory feature flag |
| P4 globals | **N** | `export let counter` is a real mutable global; `@external declare const base` is a real global import |
| P5 table + indirect call | **N** (call), table implicit | function-typed array → table + `call_indirect` |
| P6 multi-value | **X** | no multi-value; a returned array is a heap pointer |
| P7 start function | **N** | non-constant global initialiser compiles into the Wasm start function |
| P8 externref | **N** | `externref` with `--enable reference-types` |
| P9 exceptions | **X** | compiler rejects `try`/`catch`: "AS100: Not implemented: Exceptions" |
| P10 raw instructions | **E** (builtins) | `popcnt<u32>`, `i32x4.splat/add/extract_lane` builtins; SIMD needs `--enable simd` |
| P11 custom section | unresolved | no option found in `asc --help`; not searched further, so not marked X |
| P12 baseline | measured | 55 bytes; only surplus is the exported `memory` |

## What differs from the reference modules

- **P2.** The flags set limits, but `asc --help` shows only fixed names: `--importMemory` ("Imports the memory from `env.memory`"),
  `--noExportMemory` ("Does not export the memory as `memory`"). The reference's `mem` and `host.mem` are unreachable.
- **P3.** Compile error TS2554 ("Expected 0 arguments, but got 1"). The `--enable` list has `threads`, `simd`, `reference-types`, `gc`,
  `stringref`, `relaxed-simd`; no multi-memory entry.
- **P4.** The only language so far where globals are ordinary variables: `export let counter` is a mutable `i32` global in the
  global section, and an `@external` `declare const` is an immutable global import `host.base`. `bump()` returned 42.
- **P5.** The module imports `env.abort` even though the program never calls it (it comes from the bounds-checked array access). A
  host that does not provide `env.abort` cannot instantiate it; my checker auto-stubs imports, so the check still passed. This is
  unrequested surface. The table has 3 entries for 2 functions (slot 0 appears reserved).
- **P6.** The nearest thing is returning an array, which is a pointer to a managed heap object: the signature is
  `(i32, i32) -> (i32)` and the call returned a pointer (35968), not `[3, 2]`. The runtime it pulls in makes the module 3,622 bytes.
- **P7.** A start section is emitted (`start function: 0`), so this matches the reference's mechanism (unlike Rust and Zig).
- **P8.** `identity` has type `(externref) -> (externref)`. This needs `--enable reference-types`, which is off by default.
- **P9.** Not a missing feature of the output but a compile-time refusal: `try` is "Not implemented: Exceptions" in this version.
- **P10.** Builtins map directly to the instructions; the checker found `i32.popcnt` and `i32x4.add`. Unlike Rust and Zig, the simple
  splat-add-extract form kept its `i32x4.add` (Binaryen did not fold it); I did not investigate why.
- **P12.** 55 bytes, no imports, no table, no globals, memory with minimum 0 pages (there is no stack), exported `memory`. Imports
  such as `env.abort` appear only when a program needs them (see P5).

## Caveats

- Only AssemblyScript's default `incremental` runtime was used where a runtime was needed (P5, P6); `minimal`/`stub` were not tried.
- P11: "unresolved" means I found no option; it does not prove AssemblyScript cannot emit custom sections.
