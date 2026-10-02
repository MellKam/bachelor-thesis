# Rust — probe results

Toolchain: stable rustc/cargo 1.99.0 (b940084d7 2026-09-28); nightly-2026-10-02 (c36f14571) only where marked **‡**.
Target `wasm32-unknown-unknown`, `cargo build --release`, default profile, `crate-type = ["cdylib"]`.
Run all with `sh probes/run-rust.sh` inside `wasm-exposure-rust`; per-variant logs in `results/rust/`, sources in
`probes/<id>/rust/<variant>/`. Codes: see README §6. **‡** = needs the unstable `asm_experimental_arch` feature (nightly only).

| Probe | Result | One-line summary |
|---|---|---|
| P1 imports/exports | **A** | `#[link(wasm_import_module = "host")]` + `unsafe extern`; `#[unsafe(no_mangle)] pub extern "C" fn` |
| P2 memory export | **C** | linker flags in `.cargo/config.toml` |
| P2 memory import | **C** | linker flag `--import-memory=host,mem` |
| P3 multi-memory | **X** | not producible, stable or nightly |
| P4 globals | **X** stable / **E‡** | stable has only statics in linear memory; assembly declares real globals |
| P5 table + indirect call | **N** (call), table implicit | function pointers lower to a table + element segment + `call_indirect` |
| P6 multi-value | **X** stable / **E‡** | Rust functions never return multiple Wasm values; only assembly can |
| P7 start function | **A\*** partial | constructor via `.init_array`; no start section |
| P8 externref | **X** stable / **E‡** | no `externref` type in the language; assembly only |
| P9 exceptions | **X** stable / **E‡** | panics abort; real tags/try/catch only in assembly |
| P10 raw instructions | popcnt **N**, SIMD **E** | `count_ones()` → `i32.popcnt`; `core::arch::wasm32` intrinsics for SIMD |
| P11 custom section | **A** | `#[unsafe(link_section = "meta")] static` |
| P12 baseline | measured | 302 bytes (`no_std`) / 322 bytes (std), only surplus: exported `memory` |

## What differs from the reference modules

- **P2 (memory).** There is no memory declaration in source at all. Limits, stack size, export/import name are all linker arguments
  (`--initial-memory`, `--max-memory`, `-z stack-size`, `--export-memory=<name>`, `--import-memory=<module>,<name>`; all but
  `-z stack-size` appear in `rust-lld -flavor wasm --help`). Without lowering the stack size, the default 1 MiB shadow stack forces
  a 16-page initial memory, so min 1 page is impossible unless the stack is shrunk.
- **P3 (multi-memory).** `core::arch::wasm32::memory_size::<1>()` is a compile error (`assertion failed: MEM == 0` in stdarch):
  the memory-index parameter exists but only 0 is allowed. In nightly assembly, `memory.copy 1, 0` is accepted by the assembler,
  but `wasm-ld` links a single memory, and the output is **an invalid module** (`memory variable out of range: 1 (max 1)`).
  `wasm-ld --help` lists no option to create more than one memory. So the limit is in the linker, not the compiler.
- **P4 (globals).** A `static mut` is an address in linear memory; the module has no exported `counter` global and no `host.base`
  import. With `global_asm!` (nightly) `.globaltype`, `.import_module`/`.import_name` give a real imported global and a real
  mutable global; exporting it needed the linker flag `--export=counter` (so the export is **C** on top of the **E‡** declaration).
- **P5 (table).** The table is never declared; it appears because function pointers exist. The optimiser inlines a lookup into a
  constant array unless the array goes through `black_box`, so the program has to be written to *keep* the indirect call. The
  table cannot be named or sized from source. (`--export-table` was not tested.)
- **P6 (multi-value).** The default target features already include `multivalue`, but a `(u32, u32)` return, a `#[repr(C)]` struct
  return and the C ABI all compile to an out-pointer (`(i32, i32, i32) -> nil`) or a packed `u64`; none returns two Wasm values.
  Calling that export with the reference's two arguments hit a division by zero in the callee and then my `loop {}` panic handler,
  so the checker hung (recorded as `HANG`). Only a function written in assembly returned `(i32, i32)`.
- **P7 (start).** `wasm-ld` emits **no start section**. A constructor in `.init_array` becomes `__wasm_call_ctors`, and every
  export is wrapped in a `<name>.command_export` thunk that calls it first. `get()` returned 7, so the behaviour is met, but the
  mechanism differs: initialisation runs from the export wrapper, not from instantiation. Whether the constructors are guarded
  against re-running on later calls was **not tested**.
- **P8 (externref).** Stable rejects the assembly (`E0658: inline assembly is not stable yet on this architecture`), and I found no
  `externref` type in `core::arch::wasm32` (absence only confirmed for the ones I tried; not an exhaustive search). The nightly
  assembly function has type `(externref) -> (externref)`.
- **P9 (exceptions).** Stable `catch_unwind` compiles, but panics abort: `roundtrip(5)` trapped with `unreachable`, the module has
  no tag section and no exception instructions. The nightly variant emits a tag and legacy `try`/`catch` (the older encoding; the
  reference uses `try_table`), and needs `-C target-feature=+exception-handling`. The checker accepts both encodings.
- **P10 (instructions).** `u32::count_ones()` compiles to `i32.popcnt` with no special syntax. For SIMD, the intrinsic does *not*
  guarantee its instruction: LLVM rewrote `splat(a) + splat(b)` to `splat(a + b)` (scalar add), and even with opaque inputs it
  kept only lane 0 as a scalar `i32.add` when just lane 0 was used. `i32x4.add` only appeared after black-boxing the inputs and
  storing the whole result vector. The function also needs `#[target_feature(enable = "simd128")]`.
- **P11 (custom section).** Works on stable; the section name is the `link_section` string.
- **P12 (baseline).** An earlier 1.6 MB figure was a non-release `rustc` build and is withdrawn; release builds are tiny (above).

## Caveats

- Everything is `wasm32-unknown-unknown` only; `wasm32-wasip1` was not probed.
- All **‡** results are functions hand-written in assembly, not Rust code compiled to those constructs; they show the
  construct is *reachable*, not that the language expresses it.
- `#[unsafe(no_mangle)]` and `#[unsafe(link_section)]` are the edition-2024 spellings (compiler-enforced).
