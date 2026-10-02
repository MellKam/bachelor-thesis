# Grain — probe results

Toolchain: Grain 0.7.2 (release binary), image `wasm-exposure-grain`. Release build: `grain compile --release main.gr -o out.wasm`
(`--release`: "compile using the release profile") plus probe-specific flags. Run all with `sh probes/run-grain.sh`; logs in
`results/grain/`, sources in `probes/<id>/grain/<variant>/`. Codes: README §6. Stable release only.

Grain 0.7.2 uses **linear memory with reference counting** (`grain compile --help`: `--no-gc` "turn off reference counting garbage
collection"); the Wasm GC rewrite I saw as an open pull request is not in this release.

| Probe | Result | One-line summary |
|---|---|---|
| P1 imports/exports | **N** (raw types only) | `foreign wasm log: WasmI32 => Void from "host"`; `@unsafe provide let run` gives a plain `run` export |
| P2 memory export | **C\*** partial | `--initial-memory-pages/--maximum-memory-pages`; name fixed to `memory` |
| P2 memory import | **C\*** partial | `--import-memory`; import fixed to `env.memory` |
| P3 multi-memory | unresolved | no flag or syntax found in `grain compile --help`; nothing tried beyond that |
| P4 globals | **X** | module-level `let mut` is not exposed as a named Wasm global |
| P5 table + indirect call | **N** (call), table implicit | closures → funcref table + `call_indirect` (behaviour not checkable with raw ints, see below) |
| P6 multi-value | **X** | a tuple is a boxed heap value; export type `(i32, i32) -> (i32)` |
| P7 start function | **C** | `--use-start-section` replaces the `_start` export with a real start section |
| P8 externref | unresolved | the low-level modules are `WasmI32/I64/F32/F64` only; nothing else searched |
| P9 exceptions | **X** | `try` is a syntax error in 0.7.2 |
| P10 raw instructions | popcnt **E**, SIMD unresolved | `WasmI32.popcnt`; no SIMD type found |
| P11 custom section | unresolved | no option found |
| P12 baseline | measured | 3,650 bytes (raw `WasmI32` function) / 3,713 bytes (idiomatic) |

## What differs from the reference modules

- **Two layers.** Plain Grain code (`Number`, `Int32`, tuples, lists) exports functions that take and return Grain's own value
  representation, not raw Wasm values. A `Number` is tagged: `bump()` (counter 0 → 1) returned `3`, i.e. `(1 << 1) | 1`. The
  `Int32` add compiled to `(i32, i32) -> (i32)` but returned an out-of-bounds trap when called with raw `2, 3`, because Grain
  passes `Int32` boxed on the heap. Only the `@unsafe` `WasmI32`/`WasmI64`/`WasmF32`/`WasmF64` layer gives the reference's raw
  signatures (P1, P7, P10, `P12/wasmi32`). The checker's raw-value calls therefore only mean something for that layer, so the P4,
  P5, P6 and P12 `idiomatic` behaviour checks do not measure what they were meant to; their *structural* results above stand.
- **Runtime must start first.** `bump()` trapped out-of-bounds in the default build and ran with `--use-start-section`, which
  makes the runtime initialise at instantiation instead of in the `_start` export. In the default build, exports other than
  `_start` are not safe to call before `_start` has run.
- **P1.** The reference's single import is joined by an unrequested `wasi_snapshot_preview1.fd_write` import (see P12).
- **P2.** `--initial-memory-pages` and `--maximum-memory-pages` met the 1..4 limits (the first run was ok, the check only failed on
  the memory *name*): memory is exported as `memory`, and `--import-memory` imports `env.memory`.
- **P5.** The module has a funcref table, an element segment and `call_indirect` (all checked); the calls trap for the tagged-value
  reason above.
- **P7.** Without the flag the module has an exported `_start` and no start section; with it, `start function` is set and
  `get()` returned 7.
- **P9.** `try { … } catch { … }` fails to parse ("Syntax error after ' ' and before 'try'"); Grain has `exception` declarations, but
  I did not find a way to catch one in this version.
- **P12.** Even a raw one-function module is 3,650 bytes: it imports `wasi_snapshot_preview1.fd_write`, exports `memory` and
  `_start`, defines 15 functions and 20 globals, has a 64-page minimum memory and one data segment. The idiomatic variant is
  3,713 bytes and fails the raw-value check for the reasons above.

## Caveats

- "unresolved" means I did not find a way, not that Grain cannot do it. Grain's documentation site was not available when I tried it
  (404), so these rest on `--help`, the compiler's errors and what I observed in the emitted modules.
- Behaviour checks for tagged values were not rewritten; a more careful Grain-specific harness could change P5/P6 behaviour results.
