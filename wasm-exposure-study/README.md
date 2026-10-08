# wasm-exposure-study

An empirical comparison of how programming languages expose WebAssembly features to the developer. It is the evidence base for
Chapter 2 of the thesis: every claim in that chapter of the form "language X can / cannot express Y" should point at a probe in
this directory.

Status: **30 probes written and run for all eight language columns; results coded provisionally, not yet analysed.**
`results/matrix.md` is the generated overview, `results/coding.json` the hand-authored classification behind it, and
`results/<lang>/*.json` the checker's verdicts it rests on. The plan the study follows (languages, feature list, the result
vocabulary and the rules for scoring a cell) is [`../chapter-2-test-matrix.md`](../chapter-2-test-matrix.md); where this README and
that file disagree, that file wins. The capstone programs of an earlier version of the study (Game of Life, WASI `cat`) are out of
scope; their files remain in `capstones/`, `host/` and `results/capstones/` untouched.

## 1. Question

> For each feature WebAssembly provides, how much of it can a developer name, configure and control from source code in each
> language, and what additional tooling is needed to get there?

This is a question about *exposure*, not about performance, code quality or popularity. "Exposure" is measured by where a feature
lives relative to the language: in the source and understood by the compiler, in the source but opaque to it, or outside the
source altogether (see the result vocabulary in the matrix file).

## 2. Goals and non-goals

1. A **coverage matrix**: Wasm feature × language, each cell a result backed by an artifact in this repo.
2. **Observable evidence**: every cell is decided by inspecting the compiled `.wasm`, not by reading what a language says it does.
3. **Reproducibility**: pinned toolchains in containers, scripted runs, verdicts committed.

Not a performance benchmark, not a ranking of languages, not a test of language *safety* (in particular not of whether the host
boundary is checked), not a test of wx (wx is deliberately excluded so the baseline is not defined by the thesis's own language),
and not exhaustive over Wasm: only features in a released version of the spec are probed, and instruction features are sampled by
family. The matrix file lists what was left out and why.

## 3. Subjects

Seven columns. C and C++ share a column (one toolchain and target, and one module can mix them), and so do MoonBit's two backends:
the `wasm` and `wasm-gc` backends are different targets and a module uses one of them, so each probe is run on both (directories
`moonbit/` and `moonbit-gc/`), a cell takes the better backend, and a feature only one of them has carries the cost "only on the
`<backend>` backend", which counts as one obstacle (see `results/rating/README.md`).

| Column | Language / backend | Version | Memory model | Route to Wasm |
|---|---|---|---|---|
| `rust` | Rust (+ `nightly-2026-10-02` for variants that need it) | 1.99.0 (LLVM 23.1.1) | linear memory | LLVM + `rust-lld`, `wasm32-unknown-unknown`; `wasm64-unknown-unknown` with `-Zbuild-std` |
| `zig` | Zig | 0.16.0 | linear memory | self-built object + `wasm-ld` |
| `c` | C / C++ (clang from wasi-sdk 34.0) | clang 23.1.0, LLD 23.1.0 | linear memory | LLVM + `wasm-ld`, `--target=wasm32-unknown-unknown` (C++ exceptions: `wasm32-wasip1`) |
| `moonbit` | MoonBit, `wasm` backend (probe directory `moonbit/`) | `moon` 0.1.20260920, `moonc` v0.10.14 | linear memory | own backend |
| `moonbit` | MoonBit, `wasm-gc` backend (probe directory `moonbit-gc/`) | same toolchain | Wasm GC (plus a small linear memory) | own backend |
| `assemblyscript` | AssemblyScript | 0.28.20 | linear memory + runtime GC | Binaryen |
| `tinygo` | TinyGo | 0.42.0 (LLVM 22.1.4, Go 1.27.1) | linear memory + runtime GC | LLVM + `wasm-ld`, target `wasm-unknown` |
| `kotlin` | Kotlin/Wasm | 2.4.21 (`kotlinc-wasm`, JDK 25.0.4.1) | Wasm GC | own backend; WASI target (`wasm-js` where a probe needs JS types) |

The language set is not claimed to be complete. It was chosen for current use as a Wasm target and for variety in design intent.
Known omissions: Emscripten (a separate C toolchain), Go's standard compiler, Swift, Dart and others. Grain was part of an earlier
pass and was dropped; nothing of it remains.

## 4. The probes

There is one probe per feature of the list in `check/feature-list.mjs` (30 features, ordered by stabilisation: spec version 1.0, then 2.0, then 3.0). All 30 are run in all eight columns (the last nine were added after the first 21; see `PROBES.md`). A feature that is specified but not probed yet is `Pending` in `results/coding.json`.
[`PROBES.md`](PROBES.md) specifies each probe's task and exactly what the checker asserts.

```
probes/<NN>-<slug>/
  reference.wat              a hand-written module that satisfies the checker (the checker is validated against these)
  <lang>/<variant>/          one attempt: sources, `cmd` (the build command), optional `spec`, and out.wasm after a run
  <lang>/ABSENT.md           when a language offers nothing to attempt the feature with: what was checked
```

A **variant** is a different way of attempting the same task in the same language: a flag, an attribute, a nightly feature, an
inline-assembly attempt next to a library attempt. The matrix cell for a language takes the best result a developer could
reasonably reach; the variants that fell short are the evidence for the flag attached to it. A failing probe is not an error,
it is a result: the verdict says which checks failed.

Instruction features (08, 09, 11, 12, 15, 26, and the specified 16 and 24) are families probed as one unit; the verdict carries per-member results. For SIMD,
LLVM folds `extract(splat + splat)` back into a scalar add, so every LLVM-based language has a second variant that feeds the
vectors from memory; the cell then says the optimiser may drop lane operations.

## 5. Running it

Everything runs in containers; nothing is installed on the host except Docker.

```
make base-image                         # Debian + Node + WABT + Wasmtime + wasm-tools (inspection tools only)
make probe-<lang> [FEATURES="01 02"]    # build every variant of <lang> and check it   (rust zig c moonbit moonbit-gc assemblyscript tinygo kotlin)
make check-references                   # run the checker on the reference.wat files; a checker that rejects its own reference is broken
make summary [LANGS="rust c"]           # one line per variant: verdict, size, failed checks
make recheck [LANGS=...]                # re-run the checker on the binaries already built (after changing the checker); rebuilds nothing
make matrix                             # validate results/coding.json against the evidence and render results/matrix.md
make rating                             # render results/rating/rating.md (tallies and a 0-1 score) from results/coding.json and results/rating/weights.json
```

`probes/run.sh <lang>` is the runner (it executes inside the language's image). For every variant it runs `cmd` in the variant's
directory, requires an `out.wasm`, runs the checker, and writes `results/<lang>/<NN>.<variant>.txt` (build log + verdict) and
`.json` (the verdict). A build that fails, or a module that never returns from an export (20 s limit), is recorded as a result
(`BUILD-FAILED`, `HANG`).

## 6. Scoring

1. Write the program using the language's **official documentation and idioms**; record anything non-obvious in the probe's
   comments or the cell's note. Idiomatic over clever, except where a variant is explicitly an attempt to get around something.
2. Build with the language's standard toolchain. Any non-default flag, config file or post-processing is part of the variant's
   `cmd`, not hidden.
3. The **checker's verdict** decides pass or fail, never the author's impression.
4. Describe each variant that produced something in `results/coding.json` with categories (`expressed_as` native / annotation /
   config / opaque, `support` full or partial, `needs` from a closed list), or mark the cell Absent with a modifier
   (*confirmed*: the toolchain or documentation says there is no way, or rejects the attempt; *not found*: a way plausibly exists but
   none was found). The cell's result and its flags (*partial*, *needs an unstable toolchain*, *a side effect*, ...) are derived from those
   records; free-text `flags` and a `note` say what the categories cannot. The format is in `results/README.md`. `make matrix`
   refuses a missing cell, an unknown field or value, or a probe that does not exist.

The classification is a **judgement over the verdicts** and is the part most worth reviewing; it is kept separate from the verdicts
so that it can be argued with.

## 7. The checker

`check/` contains the checker; `check/features.mjs` is the authoritative definition of every probe's acceptance criteria.

- `wasm.mjs` decodes module *structure* (types including GC types, imports, memories, tables, globals, tags, exports, start, data
  segments, custom sections) with a small, self-written decoder.
- `wat.mjs` reads *instructions* from `wasm-tools print` and answers "is this opcode emitted by this exported function or anything
  it calls?". WABT cannot read Wasm GC modules, which is why `wasm-tools` is in the base image.
- Behaviour is observed by instantiating the module in Node (V8) and calling its exports. Imports the module asks for are stubbed
  generically so modules with extra imports still run. The host calls `_initialize` (WASI reactor) or `_start` (WASI command) first
  when the module exports one, and records that it had to.
- Criteria assert **structure and opcodes, never byte equality**, so different compilers can legitimately pass.
- The engine is the Node in the base image (V8); a module that uses a feature the engine rejects fails loudly at instantiation,
  which is recorded, not hidden.

## 8. Threats to validity

| Threat | Mitigation |
|---|---|
| One author, one pass; expertise differs between languages | Official docs and idioms; Absent carries *confirmed* / *not found*; every claim has a committed probe or an `ABSENT.md`; both the verdicts and the coding are reviewable |
| Probe set biases the result | Features come from the Wasm spec's released versions (module-shape features plus a representative instruction per family), not from wx's feature list; the matrix file lists what was left out and why |
| A compiler optimises the probe away | Probes are written to be non-foldable where that is possible (run-time arguments, barriers); where it is not, the verdict says which opcodes were dropped |
| Probe design artefacts mistaken for language limits | Variants try the obvious ways around a result before a cell is called Absent; checker bugs found along the way are fixed and the binaries re-checked (`make recheck`) |
| Language choice | Stated basis, known omissions named (Emscripten, others); results are for these toolchains at these versions |
| Toolchain distribution differs from the one people use | E.g. C uses wasi-sdk's clang (a Wasm-only LLVM build at a different patch level than the official release); a cross-check against official LLVM is an open point |
| Versions move | Everything is pinned and dated; results are a snapshot of 2026-10-02 (Rust, Zig, AssemblyScript, MoonBit) and 2026-10-08 (the rest) |
| Engine support conflates with language support | A module the engine rejects is recorded as such, separately from "not emitted" |

## 9. Reproducibility

Every toolchain runs inside a container built from `toolchains/<lang>/Dockerfile` (`FROM wasm-exposure-base`), each holding only
that language's pins. Platform is fixed to `linux/amd64`. `make <lang>-image` builds, `make <lang>-version` prints what is
installed, `make <lang>-shell` opens a shell with this directory mounted at `/study`.

| Toolchain | Pinned by |
|---|---|
| base image | Debian `trixie-slim` by digest; Node v26.10.0, WABT 1.0.42, Wasmtime 49.0.1 and wasm-tools 1.261.0, each verified against a SHA-256 in the Dockerfile |
| Rust | `rustup-init` SHA-256, release manifest SHA-256, a check of the compiler's commit hash; a pinned nightly (with `rust-src`) for variants that need it; host gcc from Debian for `-Zbuild-std` build scripts |
| Zig | tarball SHA-256 from ziglang.org's download index |
| C | wasi-sdk release tarball SHA-256 (matches GitHub's digest) |
| AssemblyScript | exact `package.json` version + `package-lock.json` integrity hashes (`npm ci`) |
| MoonBit | SHA-256 of the `latest` tarballs; **see caveat** |
| TinyGo | release tarball SHA-256 + Go toolchain tarball SHA-256 from go.dev |
| Kotlin/Wasm | `kotlin-compiler` zip SHA-256 + Temurin JDK tarball SHA-256 from Adoptium |

Known gaps, stated so they are not mistaken for guarantees:

- **MoonBit is not durably pinned.** It publishes only a moving `latest` and `nightly`; versioned URLs return 403 (checked
  2026-10-02). The build checks recorded hashes and will *fail*, not silently drift, once upstream releases a new version.
  Reproducing this exact version later requires the archived image.
- **Network at probe time.** `-Zbuild-std` (Rust `wasm64` and `panic=unwind` variants) downloads crates when it runs; the standard
  library's own lockfile bounds that, but the downloads are not pinned by this repository.
- **Kotlin 2.4.21 was published on the day it was pinned** (2026-10-08, a patch on the 2.4.0 line of 2026-06-03).
- The base image's apt packages (`ca-certificates`, `curl`, `xz-utils`, `libatomic1`, plus `unzip` in the Kotlin image and `gcc`
  in the Rust image) come from Debian at build time. They do not affect compiled output.
- Pinning fixes versions, not compiler provenance, and does not claim bit-for-bit identical builds.
- The built images are to be archived (`docker save`) and attached to a tagged release, so the study stays runnable if an
  upstream download disappears.

## 10. Layout

```
wasm-exposure-study/
  README.md          this file
  PROBES.md          the 30 features, the task of each probe and what the checker asserts
  Makefile           image, probe, summary, recheck and matrix targets
  toolchains/        base/ + one self-contained Dockerfile per language
  probes/            run.sh, kotlin-build.sh and probes/<NN>-<slug>/ (see §4)
  check/             the checker (features.mjs, wasm.mjs, wat.mjs, run.mjs) and its tools (summarise, recheck, matrix, validate-references)
  results/           <lang>/<NN>.<variant>.{txt,json}, coding.json, matrix.md, rating/rating.md   (see results/README.md)
  capstones/ host/   the earlier capstone programs and their shared hosts; out of scope, untouched
  attempts/          capstones.md only (the capstone write-up)
```

## 11. How the thesis cites this

Chapter 2 cites the study by commit hash and feature (e.g. "feature 16, Zig, `<hash>`"). Statements about a language's
capabilities in the chapter should reference a probe result (`results/<lang>/<NN>.<variant>.json`) or a primary source.
