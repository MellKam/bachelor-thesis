# wasm-exposure-study

An empirical comparison of how five programming languages expose WebAssembly concepts to the
developer. It is the evidence base for Chapter 2 of the thesis: every claim in that chapter of
the form "language X can / cannot express Y" should point at a probe in this directory.

Status: **protocol only — no experiments have been run yet.** Nothing below is a result.

## 1. Question

> For each construct a WebAssembly module can contain, how much of it can a developer name,
> configure and control from source code in each language, and what additional tooling is
> needed to get there?

This is a question about *exposure*, not about performance, code quality or popularity.

## 2. Goals

1. Produce a **coverage matrix**: Wasm concept × language, each cell an outcome code
   (section 6) backed by an artifact in this repo.
2. Replace assertions from documentation and memory with **observable evidence**: every cell is
   verified by inspecting the compiled `.wasm`, not by reading what a language says it does.
3. Quantify the **hidden surface**: what each compiler adds to a module that the developer did
   not write.
4. Quantify the **tooling cost** of building realistic programs (section 8).
5. Be **reproducible**: pinned toolchains, scripted runs, raw outputs committed.

## 3. Non-goals

- Not a performance benchmark (no timings, no optimisation comparison).
- Not a ranking of languages or a judgement of their design. Outcomes describe where a concept
  lives; interpretation happens in the thesis chapter, not here.
- Not a test of language *safety* beyond what is observable at the module boundary.
- Not a test of wx. wx is deliberately excluded from this study's results so the
  baseline is not defined by the thesis's own language. It may later be run against the same
  probes as a separate, clearly labelled column (thesis evaluation chapter).

## 4. Subjects

Versions are the latest stable releases found on 2026-10-02 and are pinned in each language's
Dockerfile under `toolchains/` (see section 14).

| Language | Version tested | Compilation route | Route evidence |
|---|---|---|---|
| Rust | 1.99.0 (LLVM 23.1.1) | LLVM + `rust-lld -flavor wasm` | a linker error observed during development showed `rust-lld -flavor wasm` (log not preserved; re-derive with `RUSTC_LOG`/`--print link-args` before citing) |
| Zig | 0.16.0 | object file + `wasm-ld` (in the configuration tested) | linker error text in `results/zig/P4.default.txt` |
| AssemblyScript | 0.28.20 | direct emission via Binaryen | `package-lock.json` pins `binaryen` 131.0.0-nightly.20260721 as a dependency of `asc` |
| Grain | 0.7.2 | direct emission via Binaryen | Grain's README and `@grain/binaryen.ml` dependency |
| MoonBit | `moon` 0.1.20260920, `moonc` v0.10.14 | custom backend | to confirm |

"To confirm" cells are hypotheses, not established facts. Where a language has several Wasm
targets or backends (e.g. MoonBit's linear-memory vs Wasm GC; Rust's `wasm32-unknown-unknown`
vs `wasm32-wasip1`), the target used for each probe is declared per probe and is the one that
gives the language its best chance.

## 5. Hypotheses (stated before running anything)

These come from the preliminary reading summarised in `../chapter-2-outline.md`. They exist
so the study can contradict us.

- **H1.** Memory is the least developer-controllable area: in most subjects it is implicit or
  runtime-owned, with limits and import/export decided outside the source language.
- **H2.** Module-level entities other than functions (globals, tables, tags) are rarely
  language-level constructs in any subject.
- **H3.** Multi-memory (P3) is not expressible in ordinary code in any subject.
- **H4.** Wasm-first languages (AssemblyScript, Grain, MoonBit) add more unrequested surface
  (P12) than the LLVM-based ones.
- **H5.** The boundary is unchecked in every subject: the host-facing interface is integers,
  floats and pointers whatever the language's internal safety.

A hypothesis that fails is a finding, and is reported as such.

## 6. Method part A — probes

Each probe is the smallest program that should cause one Wasm construct to appear in the
output module. Specifications and acceptance criteria are in [`PROBES.md`](PROBES.md).

For each (probe, language) pair:

1. Write the program following that language's **official documentation and examples**; record
   the pages used in the attempt log. Idiomatic over clever.
2. Build with the language's standard toolchain. If a non-default flag, config file or
   post-processing step is needed to satisfy the criteria, that is recorded, not hidden.
3. Run the checker (section 9) against the produced `.wasm`. The checker output, not the
   author's impression, decides pass or fail.
4. Assign **one outcome code**:

| Code | Meaning |
|---|---|
| **N** | Native: a language construct expresses it directly |
| **A** | Annotation: attribute / decorator / pragma on an ordinary construct |
| **C** | Build configuration: set outside the source (flags, manifest, config file) |
| **E** | Escape hatch: intrinsic, inline wasm or low-level unsafe type |
| **P** | Needs post-processing of the produced module by another tool |
| **I** | Implicit only: the construct appears but the developer cannot choose it |
| **X** | Not achievable (see rule below) |
| **‡** | suffix: only on an unstable / nightly toolchain feature (the pinned nightly is named in the results) |

A cell may carry a **partial** flag (`*`) when only a restricted form meets the criteria, with
the restriction written in the attempt log.

**Rule for X.** An X is a claim of absence and is the highest-risk result in the study. It
requires (a) an attempt log listing every documented approach tried, and (b) either a
statement from the language's docs or maintainers that it is unsupported, or a failed attempt
that can be reproduced from the committed code. "I could not find it" is recorded as
**unresolved**, not X, and is investigated before publication.

## 7. Method part B — capstone programs

Probes isolate features; capstones test whether the pieces work together in something realistic
and measure the tooling cost. Two programs, each implemented in all five languages:

1. **Life** — Conway's Game of Life. State in linear memory; the host reads the grid directly
   from the module's memory; exports `step()` and grid dimensions; one import supplies seeds.
   Optional variant with front/back buffers in two memories (reported separately, since H3
   predicts most subjects cannot do it).
2. **Cat** — a minimal `cat`/`wc` over WASI Preview 1 (`fd_read`, `fd_write`), no JavaScript
   host. Shows how each language reaches a standard host interface and what it hides.

Each capstone is built twice per language:

- **Raw build** — one identical host script (`host/`) is used for every language, with no
  generated glue. Whatever adaptation the module needs to run under it is documented.
- **Idiomatic build** — the language's recommended tooling (e.g. a bindgen tool or loader).

The difference between the two builds shows how much the ecosystem compensates for what the
language alone does not expose.

## 8. Tooling metrics (recorded per capstone build)

- Tools required beyond the compiler itself (name + purpose).
- Build commands to go from source to a running program.
- Lines of build configuration (manifests, flags files, scripts).
- Generated files the host depends on.
- Post-build steps required.
- Unrequested imports/exports in the final module (from probe P12 methodology).
- Output size in bytes, **release builds only**: each language's standard release command with default settings, nothing tuned
  (e.g. `cargo build --release`). Debug or unoptimised sizes are never reported; the exact command is recorded in the attempt log.
- Whether the shared host script ran the module unchanged.

## 9. Checker and oracle

- A script (`check/`) inspects each produced module with `wasm-objdump -x -d` and Node's
  `WebAssembly.Module.imports/exports`, then evaluates the acceptance criteria in
  `PROBES.md` and emits JSON.
- Criteria assert **structure** (an import named `host.log` of type `(i32) -> ()` exists; a
  memory with limits 1..4 is exported as `mem`), never byte equality, so different compilers
  can legitimately pass.
- Each probe ships a hand-written WAT reference in `probes/<probe>/reference.wat` showing the
  intended module shape; the checker is validated against these first (a checker that rejects
  its own reference is broken).
- Modules that require a feature the host does not support fail loudly at instantiation;
  the engine and version (Node/V8, Wasmtime) are recorded with each run.

## 10. Threats to validity

| Threat | Mitigation |
|---|---|
| Author expertise differs between languages | Follow official docs only; log sources; invite correction of any X |
| Versions move (esp. Grain, MoonBit) | Pin and date everything; results are a snapshot |
| Choosing the probe set biases the result | Probes derived from the spec's list of module entities and extensions, not from wx's feature list |
| "Impossible" claimed too eagerly | Rule for X (section 6); unresolved ≠ X |
| Engine support conflates with language support | Distinguish "not emitted" from "emitted but host rejects" in results |
| Naturalness is subjective | Not scored here; only objective counts (section 8). Judgement belongs to the thesis text |
| Standard-library defaults hide behaviour | Probe P12 deliberately measures the empty-program baseline |

## 11. Layout

```
wasm-exposure-study/
  README.md             this file: intent and protocol
  PROBES.md             probe specifications + acceptance criteria
  toolchains/           base/ + one self-contained Dockerfile per language (rust/ zig/ assemblyscript/ grain/ moonbit/)
  Makefile              <lang>-image / <lang>-shell / <lang>-version targets
  probes/<id>/          reference.wat + one subdirectory per language
  capstones/<name>/     one subdirectory per language
  host/                 the shared host scripts (Node)
  check/                checker + schema for result JSON
  attempts/<lang>.md    one short results summary per language (outcome per probe, what differs from the reference)
  results/              raw outputs: matrix.json, per-run logs, tool versions
```

Directories are created as work reaches them.

## 12. Procedure

1. Freeze the pins in `toolchains/*/Dockerfile` (done 2026-10-02).
2. Write reference WAT and the checker; validate the checker on the references.
3. Run probes P1–P12 for Rust first (toolchain already available), then each other language.
4. Review every X and every `*` for the rule in section 6.
5. Build and measure the capstones.
6. Generate `results/matrix.json`; the thesis table is generated from it, not typed by hand.

## 13. How the thesis cites this

Chapter 2 cites the study by commit hash and probe ID (e.g. "P3, Zig, `<hash>`"). Statements
about a language's capabilities in the chapter should reference a probe result or a primary
source, never this README's hypotheses.

## 14. Reproducibility

Every toolchain runs inside a container; nothing is installed on the host except Docker.

- `toolchains/base/Dockerfile` builds `wasm-exposure-base`: Debian `trixie-slim` (pinned by
  digest) plus the inspection tools used by every probe: Node v26.10.0, WABT 1.0.42 and
  Wasmtime 49.0.1. Each download is verified against a SHA-256 written in the Dockerfile.
- Each language has its own self-contained Dockerfile (`FROM wasm-exposure-base`) holding only
  that language's pins. Versions are not shared or generated between languages.
- `make <lang>-image` builds, `make <lang>-version` prints what is installed, and
  `make <lang>-shell` opens a shell with this directory mounted at `/study`. Platform is fixed
  to `linux/amd64`.

How each toolchain is pinned:

| Toolchain | Pinned by |
|---|---|
| Rust | `rustup-init` SHA-256, release manifest SHA-256, and a check of the compiler's commit hash |
| Zig | tarball SHA-256 from ziglang.org's download index |
| AssemblyScript | exact `package.json` version + `package-lock.json` integrity hashes (`npm ci`) |
| Grain | release binary SHA-256 (matches the digest GitHub publishes) |
| MoonBit | SHA-256 of the `latest` tarballs; **see caveat** |

Known gaps, stated so they are not mistaken for guarantees:

- **MoonBit is not durably pinned.** It publishes only a moving `latest` and `nightly`;
  versioned URLs return 403 (checked 2026-10-02). The build checks recorded hashes and will
  *fail*, not silently drift, once upstream releases a new version. Reproducing this exact
  version later requires the archived image.
- The base image's apt packages (`ca-certificates`, `curl`, `xz-utils`, `libatomic1`) are taken
  from Debian's repository at build time. They do not affect compiled output.
- Pinning fixes versions, not compiler provenance, and does not claim bit-for-bit identical
  builds. Determinism is measured separately (section 9).
- The built images are to be archived (`docker save`) and attached to a tagged release, so the
  study stays runnable if an upstream download disappears.
