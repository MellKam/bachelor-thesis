# Chapter 2 — draft: how existing languages expose WebAssembly (experimental findings)

Status: first draft of the empirical part only. It summarises the results of `wasm-exposure-study/` (commit to be cited once
the study is tagged). Background on the Wasm module model (2.1–2.3) and the framing of the comparison are not in this file.
Every figure and claim below traces to `wasm-exposure-study/attempts/*.md` and the logs in `results/`. Statements about what was
*not* found are marked as such; "not found" is not "impossible".

## 2.4 Experimental comparison of five languages

### 2.4.1 What was done

Five languages that compile to WebAssembly were studied: **Rust** 1.99.0, **Zig** 0.16.0, **AssemblyScript** 0.28.20,
**Grain** 0.7.2 and **MoonBit** (`moon` 0.1.20260920, `moonc` v0.10.14, linear-memory `wasm` backend). Each ran in a container
with pinned toolchain versions, and all sizes are for each language's standard release build (nothing tuned).

Twelve small *probes* (P1–P12) each tried to make one Wasm construct appear in the output module: imports and exports, memory
configuration (exported and imported), multiple memories, globals, tables with indirect calls, multi-value results, a start
function, `externref`, exception tags, raw instructions (`popcnt`, SIMD), custom sections, and an empty-program baseline. A
checker inspects the compiled binary (not the source or the language's documentation) and also instantiates the module and
calls it. Two *capstone* programs, a 64×64 Game of Life working directly on the exported linear memory and a WASI `cat`,
were then written in all five languages and run against one shared host script, with no per-language glue.

Each result gets an outcome code: **N** a language construct, **A** an annotation on an ordinary construct, **C** build
configuration outside the source, **E** an escape hatch (intrinsic, inline assembly or inline Wasm text), **X** not achievable,
with `*` for partial and `‡` for "only on a nightly compiler". "Unresolved" means no way was found, which is weaker than X.

### 2.4.2 Summary of findings

| | Rust | Zig | AssemblyScript | Grain | MoonBit |
|---|---|---|---|---|---|
| Imports / exports | A | N | A | N (raw layer only) | N |
| Memory limits and names (export / import) | C / C | C\* / C\* | C\* / C\* | C\* / C\* | C / C |
| Multiple memories | X | X | X | unresolved | unresolved |
| Wasm globals | X (E‡) | X | **N** | X | X |
| Table + indirect call | N (table implicit) | N (implicit) | N (implicit) | N (implicit) | N (implicit) |
| Multi-value | X (E‡) | X | X | X | X |
| Start function | A\* (no start section) | A\* (no start section) | **N** | C | **N** |
| `externref` | X (E‡) | X | **N** | unresolved | **N** |
| Exception tags | X (E‡) | X | X | X | X (works, no tags) |
| Raw instruction / SIMD | N / E | N / N+C | E / E | E / unresolved | E / E |
| Custom section | A | X | unresolved | unresolved | unresolved |
| Empty program, release (bytes) | 302–322 | 73 | 55 | 3,650 | 188 |

(\* partial: limits can be set but the exported or imported memory name is fixed.)

Four patterns stand out and are developed in the sections below.

1. **No language declares a memory.** In every language the memory exists implicitly and its limits are configured by flags or
   a config file. Only MoonBit lets the build file choose the exported name and the import module and field.
2. **Most module-level constructs other than functions are unreachable or accidental.** Tables appear only as a by-product of
   function pointers; tags are not producible by any language even where exceptions work; only AssemblyScript has a language-level
   Wasm global.
3. **Multi-value, multiple memories and exception tags were not reachable from ordinary source in any language.** In two
   cases (Rust, Zig) the language *accepts* a memory index, but the toolchain links a single memory and emits an invalid module.
4. **Anything touching memory beyond a high-level library is done with integers standing in for addresses.** This is discussed
   next because it is the most important practical finding.

### 2.4.3 Raw integers as pointers

At the module boundary, a Wasm pointer is just an `i32`. Rust, Zig and AssemblyScript return it as one (`cells_ptr() -> i32`)
and the host indexes the exported memory with it. That boundary is the same in every language. What differs is how much of the
program has to live at that level.

- In **Rust** the Life program keeps its grids in a `static mut` array and works through `*mut u8` raw pointers with `add`,
  all under `unsafe` (the import call is also `unsafe`). Pointer arithmetic is typed but unchecked.
- In **Zig** the same program uses an ordinary global array with indexing. The address is taken once, in `cells_ptr`, with
  `@intFromPtr`. This was the only language where the memory-touching code was not pointer arithmetic.
- In **AssemblyScript** the Life grids are a `memory.data(n)` block and every cell access is `load<u8>(addr)` /
  `store<u8>(addr, v)` on an integer address. In the `cat` program the WASI call arguments are themselves plain `i32`s: the
  program passes `<i32>BUF`, `<i32>IOV` and `<i32>NUM` (a buffer address, an iovec address and a result address) to
  `fd_read(0, <i32>IOV, 1, <i32>NUM)`, and fills the 8-byte `iovec` structure with two `store<i32>` calls at offsets 0 and 4.
  The compiler cannot tell an address from a count, so swapping `IOV` and `NUM` would compile.
- In **MoonBit** and **Grain** the Life and `cat` programs work entirely with literal addresses: the Life grids sit at 1024 and
  5120 (MoonBit) or 4096 and 8192 (Grain), the `cat` buffers at 2048 (MoonBit) and 8192 (Grain), each placed by hand below the
  point where the language's own heap starts (`heap-start-address 16384` in MoonBit, `--memory-base 32768` in Grain). Reads and
  writes are single-instruction helpers (hand-written inline Wasm text in MoonBit, `@unsafe` `WasmI32.load8U`/`store8` in
  Grain). There is no allocator, no bounds check and no distinction between an address and a number.

This is the floor, not what anyone would build a real project on. Hard-coded addresses collide silently with the runtime's own
heap if one number is wrong, a mistyped offset is a silent memory corruption, and none of it scales beyond a toy. Real code in
these languages avoids it with a standard library (Rust's `std`, Zig's `std.os.wasi`), a generated binding layer (not tested:
`wasm-bindgen`, the AssemblyScript loader or WASI shim) or an allocator the language provides; those layers are exactly what the
raw capstones left out. The finding for the thesis is narrower: *where a language does not give a typed construct for memory,
the programmer is left with an `i32` and nothing in the language relates it to the memory it points into.* In none of the five did I find a type
that ties an address to a particular memory.

The Rust `cat` is the counter-example that shows what the typed route costs: the program is 6 lines (`io::copy` on
standard input and output) and the module is 76,673 bytes with five WASI imports, against 360 bytes for the Zig version that
calls the WASI bindings directly.

### 2.4.4 Language by language

#### Rust

*Setup.* Straightforward to pin and install: `rustup`, one Wasm target (`wasm32-unknown-unknown`, or `wasm32-wasip1` for
WASI) and the bundled `rust-lld`. No extra tools for the raw builds.

*Writing.* Imports are an `extern` block with `#[link(wasm_import_module = "host")]`, exports are `#[unsafe(no_mangle)] pub
extern "C" fn`, and a custom section is a `link_section` static. All of this works on stable. The cost is `unsafe`
on every host call and every raw pointer access, and the module's shape is described partly by attributes and partly by linker
flags.

*What it exposes.* Memory is configured, not declared: the Wasm memory's minimum, maximum, the stack size and the export or
import name are all linker arguments (`--initial-memory`, `--max-memory`, `-z stack-size`, `--export-memory=<name>`,
`--import-memory=<module>,<name>`) set in `.cargo/config.toml`, a file that is neither the source nor `Cargo.toml`. Because the
default shadow stack is 1 MiB, an initial memory of one page is only possible after shrinking it. Function pointers produce a
table, an element segment and `call_indirect` without ever naming the table, and the optimiser inlines a constant lookup unless
the test goes through `black_box`.

*What it cannot do (stable).* Wasm globals, multi-value results, `externref` and exception tags were not reachable. A `static mut`
is an address in linear memory, a tuple or struct return becomes an out-pointer even though the `multivalue` target feature is on
by default, and panics abort (`catch_unwind` compiled, but `roundtrip` trapped with `unreachable`). On a pinned nightly
(`nightly-2026-10-02`) hand-written `global_asm!` produced all four, but those functions are written in assembly, not Rust, and
`global_asm!` on wasm32 is rejected on stable (`E0658`). The second finding is that SIMD intrinsics are not guaranteed to emit their
instruction: LLVM rewrote `splat(a) + splat(b)` to a scalar add, and an `i32x4.add` only survived after hiding the operands from
the optimiser.

*Multiple memories.* `core::arch::wasm32::memory_size::<1>()` is a compile-time error (`MEM == 0`). With assembly, `memory.copy 1, 0`
is accepted by the assembler, but the linker produces a single memory and the module is invalid. The limit is in the linker.

*Verdict.* Everything common worked on stable; the module-level concepts beyond functions and one memory are not in the
language, and the build command is part of the program.

#### Zig

*Setup.* A single tarball with a SHA-256; no other tools. The documentation shipped with the compiler (`--help`) lists the Wasm
linker options.

*Writing.* The most direct import syntax of the five: `extern "host" fn log(x: i32) void;` states the import module in the
language's own `extern` syntax, and `export fn` exports. Plain arrays gave stable addresses, which made the Life program the
safest of the memory-touching versions. WASI is reachable through bindings in the standard library (`std.os.wasi.fd_read`), which
kept the `cat` module to 360 bytes.

*What it exposes.* The same configuration-over-declaration pattern as Rust: `--initial-memory`, `--max-memory`, `--stack`,
`--import-memory`, `--export-memory`, `--export-table`, `--import-table` are flags. None takes a name, so the memory is always
exported as `memory` and imported as `env.memory`; the reference module's `mem` and `host.mem` were unreachable. `@wasmMemorySize(i)`
and `@wasmMemoryGrow(i, n)` take a memory index but nothing declares a second memory.

*What it cannot do.* Globals (`extern "host" const base: i32` is a data symbol, not a global import; `export var counter` exports an
immutable global holding the variable's *address*), multi-value (a struct return becomes an out-pointer), `externref`,
exception tags (error unions compile to ordinary control flow) and custom sections (three `linksection` spellings put the bytes in
the data section). A constructor in `.init_array` runs, but there is no start section. A SIMD result was only emitted
as `i32x4.add` once the operands went through `volatile` memory, the same optimiser effect as in Rust (the folded output was not
inspected).

*Verdict.* A small toolchain with the shortest import syntax and ready-made WASI bindings, and with the same missing
module-level concepts as Rust.

#### AssemblyScript

*Setup.* `npm` with the `assemblyscript` package; the lockfile pins its Binaryen dependency. One extra runtime (Node) beyond the
compiler itself, but nothing else.

*Writing.* TypeScript-shaped syntax with Wasm types (`i32`, `u8`). `@external("host", "log") declare function` is the import
and `export function` the export. Of the five it exposed the most Wasm entities as ordinary language features: `export let
counter` is a real mutable Wasm global, an `@external declare const` is a real global import, top-level initialisers compile into a
true start section, and `externref` works under `--enable reference-types`. Builtins map one-to-one to instructions
(`popcnt<u32>`, `i32x4.add`), and the splat-add-extract form kept its `i32x4.add` without any trick.

*What it exposes, and where it stops.* Memory limits come from `--initialMemory`/`--maximumMemory` (`--importMemory` for the import),
with fixed names `memory` and `env.memory`. There is no multi-value or multi-memory (`memory.size(1)` is a type error, and the
`--enable` list has no multi-memory entry), and `try`/`catch` is refused at compile time ("AS100: Not implemented: Exceptions").
A returned array is a managed heap pointer, so the exported signature is `(i32, i32) -> (i32)` and the result is a number that
only means something to the AssemblyScript runtime. The P5 module (a lookup in an array of functions) imports `env.abort` although the program never calls it; the cause was not
investigated. It is an import the host must supply, and an unrequested dependency.

*Raw pointers.* Its low-level layer is `load<u8>(addr)`/`store<u8>(addr)` on integer addresses (see 2.4.3). That layer is
used in both capstones, and for `cat` the program builds the WASI `iovec` by hand.

*Verdict.* The language that comes nearest to exposing Wasm concepts as language features (globals, start, `externref`,
instruction builtins), and the smallest modules (55 bytes empty, 408 for Life), with a clear refusal where a feature does not exist.

#### Grain

*Setup.* A single release binary with a published checksum. Compilation was noticeably slower than the others, on the order of ten seconds per
module in this setup (not timed precisely), and the compiler writes a `main.gro` object file and a `target/` directory of about twenty generated stdlib
files next to the source. Its documentation site returned 404 during the study, so several results rest on `--help`, compiler
errors and the emitted modules.

*Writing.* Grain 0.7.2 uses linear memory with reference counting (`--no-gc` turns it off); it has not moved to the Wasm GC
proposal in this release. Ordinary Grain code uses the language's own value representation: a `Number` is tagged
(a counter at 1 was returned as `3`) and an `Int32` is boxed on the heap. Calling exported functions with raw Wasm values trapped
with out-of-bounds accesses, and the runtime must be started first (the host had to call `_start`, or the module be built with
`--use-start-section`). Only the `@unsafe` `WasmI32`/`WasmI64`/`WasmF32`/`WasmF64` layer gives the reference signatures, and that
layer was used for imports (`foreign wasm`), the start-section probe and both capstones.

*What it exposes.* Limits through `--initial-memory-pages`, `--maximum-memory-pages`, `--import-memory`, with fixed names. A start
section through `--use-start-section`. No globals, multi-value, `externref` or exception tags were found: tuples are boxed values,
and `try` is a syntax error in this version.

*Cost of the baseline.* The smallest raw module is 3,650 bytes, importing `wasi_snapshot_preview1.fd_write`, exporting `_start`, with
20 globals and a 64-page minimum memory. The `cat` came to 3,915 bytes. I did not find the standard-library module for file I/O
(`from "sys/file"` failed), so `cat` used raw `fd_read`/`fd_write` imports.

*Verdict.* A language with its own runtime and value model; the platform is reachable only through a small unsafe layer
and the interface a host sees depends on which layer the code is in. Its strength (a high-level, memory-managed language
that compiles to Wasm) is not what these probes measured.

#### MoonBit

*Setup.* One toolchain installer (`moon`, `moonc`, core library). The downloads are only published as a moving `latest`: every
versioned URL returned 403, so the exact version used cannot be re-downloaded once a newer one is released. This matters for
reproducibility and is recorded as a limitation.

*Writing.* `fn log(x : Int) = "host" "log"` declares an import in the language, and the exports, memory limits, exported memory
name, imported memory (module and field) and heap start address live in `moon.pkg.json`. This was the only toolchain where the
memory's name, limits and import were fully configurable. `Int` is a raw `i32`, so exports have the reference signatures and the
checker's raw calls worked unchanged. `fn init` becomes the start function, `#external type` becomes `externref`, and
`extern "wasm"` embeds hand-written Wasm text for any instruction (it provided `popcnt` and SIMD directly).

*What it cannot do.* Globals (`Ref[Int]` is a heap cell), multi-value (a tuple return is a pointer), and exception tags:
`raise`/`try`/`catch` run correctly but compile to ordinary control flow with no tag section. No second memory or custom section
was found.

*Awkward parts.* There is no way to take an array's address, so the Life grids and the `cat` buffers are at fixed addresses
read through inline Wasm text (see 2.4.3). `init` is a reserved name, so the Life module's `init` export had to be renamed in
the link config (`"init_grid:init"`); `#export_name` was rejected outside a "foreign library" package. The Wasm-GC backend was not
probed.

*Verdict.* The most configurable from the build file and the most direct escape hatch (inline Wasm), with a tidy baseline (188
bytes, no unrequested imports or exports). It is at its weakest where a program needs memory it does not allocate itself.

### 2.4.5 Setup and writing effort

| | Setup | Writing the capstones | Generated files / extras |
|---|---|---|---|
| Rust | `rustup` + target | 63 lines (Life), 6 (cat); heavy `unsafe` | `Cargo.lock` |
| Zig | one tarball | 42 / 13 lines; plain arrays | none |
| AssemblyScript | `npm` install | 38 / 18 lines; `load`/`store` everywhere | none |
| Grain | one binary; slow compile | 50 / 29 lines; `@unsafe` throughout | `main.gro`, ~20 stdlib files |
| MoonBit | installer, version not re-downloadable | 44 / 24 lines; plus 20 and 12 lines of config; inline Wasm text | `_build/` |

Line counts are of programs written once by one author and are rough. All ten programs passed the shared host; the question
the table answers is what each took, not whether it worked. None of the five needed a code generator or a post-build tool for
the raw builds.

### 2.4.6 Limits of this evidence

- One author wrote every program once, with the documentation available at the time; some "unresolved" cells (Grain, MoonBit custom
  sections, `externref`, multiple memories) may have a solution I did not find.
- Only raw builds were measured. The idiomatic ecosystem layers were not exercised, so the tooling cost shown here is a lower bound.
- Versions are snapshots of 2026-10-02; Grain and MoonBit in particular change quickly, and MoonBit's version cannot be re-downloaded
  later.
- Not measured: build time, byte-for-byte reproducibility, a WASI build of the Life program (it needs no OS interface, so every language built it for the freestanding target), MoonBit's `wasm-gc` backend, and
  whether any language checks the host boundary.
- Hypothesis H5 of the study plan ("the boundary is unchecked in every language") is *not* tested by these results and should not
  be claimed.
