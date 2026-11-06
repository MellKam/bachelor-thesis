# Integration criteria

The feature probes (`PROBES.md`) ask how much of WebAssembly a developer can name and control from source. This file defines
the second axis: **what it costs to use the module that comes out**. Can it run outside a browser (WASI), can it be a component,
can it talk to JavaScript without hand-written glue, can it be debugged, how large is it, and how many tools did the build need.

**Status: I1–I5 are probed in all columns (`make integration-<lang> [CRITERIA=I1]`, `make integration-matrix`, `make integration-rating`); I6 is measured and reported on its own, not scored.** The coefficients are our choice and may not be ideal; the ranking is re-run under random perturbations of all of them to show which orderings are stable.

What differs from the first draft of this file, decided while building it:
- **A language without direct support is Absent, not rated through a hand-written ABI**. Hand-built evidence for Zig, AssemblyScript and Kotlin components is kept under `integration/i2-component/<lang>/hand-abi-wasm-tools/` and is not scored.
- **I3 has no `restricted-host` obstacle**: the host is JavaScript by definition. The `raw` route (`hand-written`) reuses the `words` floor builds of I5 and the glue in `integration/host/words-raw.mjs`.
- **I4** is decided by a debug build of `life` with an exported `crash_here` that traps: name section, DWARF or source-map reference, and whether the V8 stack of the trap names the function (informational; Kotlin throws a `WebAssembly.Exception` with no stack, MoonBit's name is mangled `crash__here`). The cell is full with names plus DWARF or a source map, partial with names only.
- **I5 `default` builds** are the tool's invocation without any size or speed option (Rust plain `--release`, C wasi-libc `-O2`, TinyGo wasip1, Swift non-embedded, Zig `-O Debug`, MoonBit `moon build` debug, AssemblyScript plain `asc`); Kotlin has one build, so the floor is repeated. `cat` sizes come from the I1 builds named in `results/integration.json` (`I5.cat`). The size used is the smaller of the raw bytes and the bytes after `wasm-opt -Oz`.
- **I6** is measured by `make integration-i6` (toolchain footprint, cold build of the `words` floor build) and listed with the extra tools of each language's best route, in a section of its own; it is not scored.
- MoonBit is one column. A route that exists only on the wasm backend does **not** carry `other-backend` here, after the component tutorial was checked: the backend is one choice per project and its cost is already in the exposure axis. `other-backend` stays in the exposure rating only.

## Rules (the same as for the feature probes)

- The checker decides, on a built artifact. Tooling quality, documentation and popularity are impressions and are not criteria.
  Where tooling matters it becomes a yes/no with evidence (a command that was run and what it printed).
- Everything runs in the language's Docker image. New tools (`wit-bindgen`, `wasm-bindgen-cli`, `jco`, `wasm-opt`, ...) are pinned
  in `toolchains/<lang>/Dockerfile` with a version and a digest, the way the existing tools are.
- A cell is reached by one or more **variants**; the one that stands for the cell is chosen like in `check/cells.mjs`
  (most complete, then fewest obstacles).
- Two scores are reported side by side: **exposure** (the existing rating) and **integration** (this file). The combined score is a
  weighted sum computed last (see "Scoring").

## Programs

The criteria are tested on small example programs, each with one shared host script that is identical for every language
(`integration/host/`). The existing capstone hosts are not reused as they are: `host/life.mjs` imports `check/probes.mjs`, which
no longer exists. The contracts are kept.

| Program | What it exercises | Used by |
|---|---|---|
| `life` | pure compute on linear memory, no allocation, no strings. 64x64 torus, 100 steps, checked against a JS reference. Contract: import `host.random() -> i32`; export `memory`, `init()`, `step()`, `cells_ptr() -> i32`, `width() -> i32`, `height() -> i32` | I5 |
| `cat` | a WASI command: stdin to stdout unchanged (text, empty, 100000 random bytes), exit code 0 | I1, I5 |
| `words` | a string in, a record out, so the allocator, string handling and the host boundary are all involved | I2, I3, I5 |

`life` shows the floor of a language with no runtime help. `words` shows what strings and records cost. The pair matters: a
language can be tiny on `life` and large on `words`.

### `words`

WIT (the component form):

```wit
package study:words@0.1.0;
interface words {
  record stats { words: u32, bytes: u32, longest: string }
  analyse: func(text: string) -> stats;
}
world words-world { export words; }
```

- `words`: runs of non-ASCII-whitespace bytes (space, tab, `\n`, `\r`). `bytes`: length of the input in UTF-8 bytes. `longest`: the
  first longest word, by byte length.
- Inputs: `"the quick brown fox"` -> (4, 19, "quick"); `""` -> (0, 0, ""); `"  a  bb ccc  "` -> (3, 13, "ccc");
  `"héllo wörld"` -> (2, 13, "héllo"); a 100 000-byte text of repeated words (stresses allocation).
- **Core-module form** (the floor, used when no component or binding generator is involved): export `memory`, `alloc(len: i32) ->
  i32`, `analyse(ptr: i32, len: i32) -> i32` which returns the address of a 16-byte record `{ words: u32, bytes: u32,
  longest_ptr: u32, longest_len: u32 }` in linear memory. The host owns the input (it calls `alloc`, writes, calls `analyse`).
  No free function is required: the program is run once per instance.

## The criteria

Each criterion has an id `I<n>` and a directory `integration/i<n>-<slug>/<lang>/<variant>/` (sources and a `cmd` file, as in
`probes/`). A criterion a language cannot attempt has an `ABSENT.md` in `integration/i<n>-<slug>/<lang>/` saying what was checked.
Verdicts are written to `results/integration/<lang>/I<n>.<variant>.json`; the hand coding is `results/integration.json`.

| # | Criterion | Program | Scored as |
|---|---|---|---|
| I1 | WASI | `cat` | cell (reach x route) |
| I2 | Component Model | `words` | cell |
| I3 | JS host bindings | `words` | cell |
| I4 | Debuggability | a deliberately trapping `life` build | cell, yes/no per sub-check |
| I5 | Size | `life`, `cat`, `words` | measured figure, normalised score |
| I6 | Toolchain cost | the build recipes | figures, not scored |

### I1 WASI

Build `cat` for the language's WASI target and run it under `wasmtime run`. **Pass:** stdout equals stdin for text and empty input, and the exit code is 0. Equality on 100 000 random bytes is recorded as
*binary-safe* (informational): a text API such as Kotlin's `readln` fails it although WASI works. **Recorded:** the WASI version from the module's imports
(`wasi_snapshot_preview1` = p1; component imports `wasi:cli/...@0.2.x` = p2; whatever 0.3 looks like when a toolchain emits it), the
target name, and whether a command (`_start`) or a reactor (`_initialize`) was produced. A module that needs a JS-only glue to run
does not pass.

### I2 Component Model

Implement the `words` WIT world and build a component. **Pass, all of:**
1. `wasm-tools validate --features component-model` accepts the file and `wasm-tools print` shows a component (not a core
   module);
2. `wasm-tools component wit` shows an export that is type-equal to `study:words/words` (checked by the checker, not by eye);
3. `wasmtime run --invoke 'analyse("héllo wörld")' words.wasm` returns `{words: 2, bytes: 13, longest: "héllo"}` and the other
   inputs match too.

**Route** (see below): `builtin` if the compiler emits a component directly (e.g. a `wasm32-wasip2`-style target); `official-tool` if a
Bytecode Alliance tool turns a core module into one (`wasm-tools component new` plus a WASI adapter, `wit-bindgen` for the guest
bindings); `community-tool` otherwise; `hand-written` if the developer writes the canonical-ABI glue.

### I3 JS host bindings

Call `analyse("héllo wörld")` from Node with a string and get a record back, using whatever the language's tooling offers.
**Pass:** the shared Node host `integration/host/words.mjs` calls the exported function through the variant's glue and the result
matches all five inputs. The host script is written once per *kind* of glue (raw core module, generated JS, `jco`-transpiled
component), never per language.

**Route:** `builtin` / `official-tool` / `community-tool` for generated glue (`wasm-bindgen`, Emscripten-style loaders, Kotlin's own
JS loader, `jco transpile` on an I2 component); `hand-written` when the developer writes the string marshalling (`alloc`, copy,
`TextDecoder`). **Recorded as a figure:** the number of lines of hand-written glue, and whether the generated JS is needed at run
time (a language whose module runs only with its own JS loader also has the `restricted-host` obstacle).

Companion code written by a tool on the JS side counts: it is a route (`official-tool` or `community-tool`), not a failure.

### I4 Debuggability

Three yes/no sub-checks on a build made with the toolchain's debug option, plus a trap: `life` with an out-of-bounds index in
`step` added to the build.
- **names:** the module has a `name` section with the function names (`wasm-tools`).
- **debug-info:** DWARF sections or a source-map reference is present (and the tool that produced it is recorded).
- **trap-location:** running it in Node, the exception's stack names the source function (not `wasm-function[7]`).

The cell is `full` when all three hold, `partial` when some do; reach and route follow the same rule as the other cells.

### I5 Size

For each program (`life`, `cat`, `words`) and each language, two builds:
- **floor:** the lowest-level route that produces the fixed contract above (what the feature probes use);
- **default:** the route the language's official documentation leads a newcomer to (Swift via SwiftPM and the Wasm SDK, Kotlin via the
  Wasm backend of the Kotlin compiler, Rust via `cargo build --release`, ...). Where this equals the floor, it is the same file.

For each build, record raw bytes and the bytes after `wasm-opt -Oz` (Binaryen, pinned in the base image; GC modules with
`--enable-gc` and the other needed `--enable-*` flags), plus the build command. The release optimisation level is the language's own
size setting (`-Oz`, `opt-level = "z"`, `-Osize`, ...); this is written in each `cmd`.

A program a language cannot build (no WASI target, say) has no size for it; this is shown, not scored as 0.

### I6 Toolchain cost

Reported in a section of its own, never scored and never part of the integration or combined score: it asks how heavy the official
toolchain is, which is a different question from how well the module integrates. Three plain figures per language, from
`make integration-i6` and the cells' `tools` lists:
- **footprint:** size of the official toolchain needed to build to Wasm (compiler, std library or sysroot or SDK, and the runtime the
  compiler itself needs: Node for AssemblyScript, Go for TinyGo, a JDK for Kotlin), stable toolchain only, measured in the pinned
  image (`integration/measure-i6.sh`);
- **cold build** of the `words` floor build (a 50-line program, so it only separates slow starters);
- **extra tools** of the best route of each of I1-I3 (the route factor already prices them, which is why they are not scored again).

## Route and obstacles

A cell's **route** is the integration analogue of `expressed_as`: how the capability is reached.

| Route | Meaning |
|---|---|
| `builtin` | the language's own compiler / standard toolchain does it, with nothing added to the build recipe |
| `official-tool` | one or more extra tools published by the language's own project or the Bytecode Alliance (`wasm-bindgen`, `wit-bindgen`, `wasm-tools component new`, `jco`) |
| `community-tool` | extra tools from a third party, or a fork of the compiler |
| `hand-written` | the developer writes the glue (canonical ABI, string marshalling, WASI shims) |

Each cell also records `tools` (the named extra tools, which feed I6) and the same closed `needs` list as the exposure cells where it
applies (`nightly-compiler`, `experimental-api`, `restricted-host`, `extra-runtime`). `other-backend` is not
used here. Absent has the same two modifiers, `confirmed` and `not found`; a `not found` counts 0 in the mean, as in the exposure rating.

## Scoring

- **Cell score** = reach (full 1, partial 0.5) x route factor x product of the `needs` factors in `results/rating/weights.json`
  (the existing numbers; `restricted-host` etc. keep their values).
- **Route factors** (least to most damaging): `builtin` 1.00, `official-tool` 0.85, `community-tool` 0.70, `hand-written` 0.50.
  The order is the reasoned part; the numbers are read off it, as for the obstacles.
- **Size score**, per program: `1 - log10(size / smallest size among languages) / 3`, clamped to `[0, 1]` (1000x the smallest is 0).
  The score of a language is the mean over its programs and over the floor and default builds. Log scale so that one 600 KB runtime
  does not flatten everyone else.
- **Integration score** = weighted mean of I1-I5, criterion weights: I1 3, I2 3, I3 2, I4 1, I5 2. I6 is reported, not scored.
- **Combined score** = `w_exposure x exposure + w_integration x integration`, 0.6 / 0.4, in `integration-weights.json` under `combined`.
  `rating.md` re-ranks under random perturbation of every number (the order of the routes and obstacles kept), as for exposure, and
  calls an ordering robust only at >= 95% of runs. That is also how the 0.6 / 0.4 split is tested.

## Where this goes in the repository

| Item | Path |
|---|---|
| Criterion sources and `cmd` files | `integration/i<n>-<slug>/<lang>/<variant>/` |
| Shared hosts | `integration/host/{cat,words,life,bindings}.mjs` |
| Checker | `check/integration.mjs` |
| Hand coding | `results/integration.json` (`variants` / `absent`, `route`, `tools`, `needs`) |
| Verdicts | `results/integration/<lang>/I<n>.<variant>.{json,txt}` |
| Report | a section "Integration" in `results/rating/rating.md`, chart data in `rating.json` |
| Run | `make integration-<lang> [CRITERIA="I1 I2"]`, `make integration-matrix` |

## Order of work

Done: the specification, I1-I6, the integration and combined scores (`make integration-rating`), the charts in `viz/` (section 8 integration on
its own, section 9 toolchain cost, section 10 the combined result) and the doc sync. Not done: a second C column built with Emscripten for the other criteria (Emscripten is used only for the JS-bindings criterion, as a variant of the C cell).

## Open points

- The WASI target a language calls "the" target changes (p1 now, p2 or p3 later). The cell uses what the official documentation
  names as the default on the pinned toolchain; other versions are variants.
- Whether `wasmtime run --invoke` in the pinned Wasmtime accepts record results as written above must be checked in step 2; if not, a
  small Rust or Node (`jco`) host replaces it, identical for every language.
- Emscripten is installed in the C image for I3 only. It is counted as `official-tool` (a second toolchain beside wasi-sdk); counted as C's own toolchain it would be `builtin` and move C's combined score by about +0.01 without changing any rank.
