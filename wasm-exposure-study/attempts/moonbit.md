# MoonBit — probe results

Toolchain: `moon` 0.1.20260920 (914d7da), `moonc` v0.10.14+7d59c7ec9, image `wasm-exposure-moonbit`, backend `--target wasm`
(linear memory; the `wasm-gc` backend was not probed). Release build: `moon build --release --target wasm`, output copied to
`out.wasm` (`moon build --help`: `--release` "Compile in release mode"). Link options are in each variant's `src/moon.pkg.json`
(`link.wasm`), documented in the MoonBit package-configuration docs: `exports`, `import-memory`, `memory-limits`, `shared-memory`,
`export-memory-name`, `heap-start-address`. Run all with `sh probes/run-moonbit.sh`; logs in `results/moonbit/`, sources in
`probes/<id>/moonbit/<variant>/`. Codes: README §6. Stable release only.

| Probe | Result | One-line summary |
|---|---|---|
| P1 imports/exports | **N** | `fn log(x : Int) = "host" "log"`; `exports` list in `moon.pkg.json` |
| P2 memory export | **C** | `memory-limits {min:1,max:4}`, `export-memory-name: "mem"` |
| P2 memory import | **C** | `import-memory {module:"host", name:"mem"}` |
| P3 multi-memory | unresolved | no link option for more than one memory; inline wasm only supports a function |
| P4 globals | **X** | module-level values live on the heap; no global exports or imports |
| P5 table + indirect call | **N** (call), table implicit | function-typed array → table + `call_indirect`; raw `Int` arguments work |
| P6 multi-value | **X** | tuple return is a heap pointer: `(i32, i32) -> (i32)` |
| P7 start function | **N** | `fn init { … }` becomes the Wasm start function |
| P8 externref | **N** | `#external type Obj` → `externref` |
| P9 exceptions | **X** (mechanism) | `raise`/`try`/`catch` behave correctly but compile to plain control flow, no tags |
| P10 raw instructions | **E** | `extern "wasm" fn … = #|(func … i32.popcnt)` inline WAT, for both popcnt and SIMD |
| P11 custom section | unresolved | no option found |
| P12 baseline | measured | 188 bytes; no imports, no unrequested exports |

## What differs from the reference modules

- **P1/P5/P12: raw values cross the boundary.** `Int` is an `i32`, so exports have the reference's signatures and the checker's raw
  calls work as written (unlike Grain). `call_slot(0,5) == 10` and `call_slot(1,5) == 105` passed.
- **P2.** The only language so far where the memory is fully configurable from the build file: limits, the exported name (`mem`) and
  the imported module and field (`host.mem`) all matched the reference.
- **P4.** `let counter : Ref[Int]` is a heap object; the module has no global section entries for it, no `host.base` import and no
  `counter` export. `bump()` returned 1, not 42.
- **P6.** Despite the backend using the multi-value proposal internally (MoonBit's docs, as returned by a search snippet), an exported
  tuple return is `(i32, i32) -> (i32)`: it returned a pointer (11608), not `[3, 2]`.
- **P7.** `fn init` yields a start section; `get()` returned 7. Unlike Rust/Zig, the mechanism matches the reference.
- **P8.** `#external type` appears as `externref` in both the argument and result of `identity`, with other helper signatures
  (`(i32) -> externref`, `(externref) -> i32`) added by the runtime.
- **P9.** `suberror` needs a payload-carrying constructor (`priv suberror Boom { Boom(Int) }`); `try … catch { Boom(n) => n } noraise`
  worked (`roundtrip(5) == 5`), but the module has no tag section and no exception instructions. Behaviour met, mechanism not.
- **P10.** Inline WAT puts `i32.popcnt` and `i32x4.add` straight into the output. Because the function body is hand-written Wasm,
  this is the strongest escape hatch of the five languages, but it is also unchecked text.
- **P12.** 188 bytes: no imports, a 1-page memory, a table, one data segment, `name` and `producers` custom sections; only `add` is
  exported. (Reference exports exactly `add`.)

## Caveats

- Only the `wasm` backend was probed. `wasm-gc` uses a different memory model and would change P2–P6 results.
- The MoonBit install is not durably pinned (see README §14): the exact `latest` build of 2026-10-02 may not be re-downloadable.
- "unresolved" means no option found in the docs I could reach (one docs URL was a 404), not that MoonBit cannot do it.
