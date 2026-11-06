# Chapter 2 (revised) — storyline and structure

Status: proposal for discussion. Nothing here is written as thesis prose yet.

## 1. The one-sentence story

> A WebAssembly module is a fixed set of declared entities plus a small execution model.
> Source languages differ enormously in *how much of that set a developer can name, configure
> and control from source code*, and the answer is mostly decided by the language's compilation
> path and runtime model, not by what Wasm can do.

Chapter 1 *asserts* that languages reach Wasm "through their own model" and expose that model
instead of the platform's. Chapter 2 has to **earn that claim with evidence**. That is the
chapter's job: not a Wasm tutorial, not a language survey, but an evidence-backed answer to
"what does the platform offer, and what does each language let you reach?"

Tone constraint: describe, don't judge. The chapter shows *where each concept lives* (source
construct, attribute, build flag, library, or nowhere). Whether that is good is argued in the
synthesis section, using stated criteria, not scattered through the case studies.

## 2. The analytical lens (introduced in 2.2, used in 2.4–2.6)

Without a fixed lens, five case studies turn into five unrelated feature lists. Proposal:
every Wasm concept is placed on one **exposure ladder** for each language.

| Level | Meaning | Typical example |
|---|---|---|
| 0 Not expressible | Cannot be produced from source | (e.g. a table in a language with no way to declare one) |
| 1 Implicit | Compiler/runtime decides; developer cannot influence | Memory layout owned by a runtime |
| 2 Build configuration | Set outside the source: linker flags, config files | Memory limits via a linker option |
| 3 Annotation | Attribute/decorator on an ordinary construct | `#[export_name]`, `@external` |
| 4 Escape hatch | Intrinsics, inline wasm, unsafe low-level types | `memory.grow` builtin, inline WAT |
| 5 First-class construct | A typed declaration in the language | `memory m: ...;` |

Plus four **evaluation criteria** taken from your request, defined once in 2.2 so they can
be applied consistently later: **coverage** (how much of the platform is reachable),
**control** (can you choose, not just reach), **safety** (what the type system checks across
the boundary), **naturalness** (does it read as the language, or as a bolt-on). Naturalness
is the subjective one; define it operationally (does it need a second syntax, a second tool,
or a build step the rest of the language does not?).

Open question for you: is a ladder too wx-flattering (level 5 reads as "best")? Alternative is
to present the levels as a neutral *spectrum of locus* (where the concept lives) and never
rank them. I lean towards neutral wording in 2.4–2.5 and rank only in 2.6.

## 3. Proposed section structure

### 2.1 What a Wasm module is (the platform surface)
Purpose: define the vocabulary every later section uses. Keep it to what the case studies
need.
- Module = types, functions, tables, memories, globals, tags + imports, exports, start
  function, data/element segments, custom sections. Separate index spaces.
- Binary vs WAT vs embedder. One small WAT example (import → call → export), reused.
- The sandbox property: no ambient authority; everything crosses via imports/exports.
  Nuance: imports can grant arbitrary authority; WASI is a host interface, not core.
- **Why this list is the "platform surface":** it is the set of things a developer might
  reasonably want to *name*. This sets up the exposure question.

### 2.2 Execution model facts that constrain a source language
Only facts that change a compiler's job. Each gets one "so what for languages" sentence.
- Typed stack machine and validation (types checked, not trusted).
- Structured control flow only (no goto → CFG reconstruction for C-like sources).
- Four value types in the MVP, linear memory is bytes, pointers are integers. Memory is
  *untyped*, bounds-checked traps, no memory safety inside a module.
- Traps and (separately) exception handling with tags.
- Function references, indirect calls, tables.
- Multi-value, and its consequence for calling conventions.
- Then the lens (section 2 above) and criteria.

### 2.3 The platform is a moving target: extensions and what they add
Group by *what they change for source languages*, not chronologically:
- More memory: multi-memory, memory64, bulk memory, threads/atomics.
- More value kinds: reference types, SIMD, GC types.
- More control: exception handling, tail calls, stack switching.
- Status: which are standardised (Wasm 3.0?), which are proposals, which are implemented by
  which engines. **Needs verification against the spec repo and the proposals table**, and
  must be dated, because this is the part that goes stale fastest.
- Takeaway: the extension set is exactly where "language model vs platform model" divergence
  becomes visible (e.g. GC extension vs a language that ships its own collector).

### 2.4 Three routes from source to Wasm (how the toolchain shapes exposure)
This is the section that explains *why* exposure differs; it is the analytical core and
probably the chapter's most original contribution.
- **Route A: via LLVM object files and a linker** (Rust, Zig). Wasm entities appear as
  symbols with linker-level conventions; memory limits, exported symbols, imported memory
  are `wasm-ld` options; C ABI conventions govern argument passing. Consequence: much is
  level 2 (build config) and level 3 (attribute).
- **Route B: direct emission with an optimiser library** (AssemblyScript, Grain; both reportedly
  use Binaryen, to verify). Compiler owns the whole module; entities are produced directly.
- **Route C: custom backend** (MoonBit). Own IR, multiple backends including Wasm GC.
- Plus the **interface layer** that sits on top regardless of route: raw C ABI,
  wasm-bindgen, WASI, Component Model/WIT. Explain it once here so case studies can say
  "this is a layer, not the language".

### 2.5 Case studies (one fixed template per language)
Same subsections for each language, in this order, so the reader can compare by flipping:
1. Compilation route and runtime model (what the language brings along).
2. Imports.
3. Exports.
4. Memory: access, size/limits, import/export of memory, allocator story.
5. Other module entities: globals, tables, start function, custom sections, tags.
6. Reference types, multi-value, SIMD, atomics, exceptions, GC (feature coverage).
7. Escape hatches: inline wasm, intrinsics, unsafe.
8. Boundary safety and ergonomics: what the type system checks, what the host can break.
9. Stated limitations (from the language's own docs/issues, cited).

Order of languages: Rust, Zig (Route A, shared LLVM story) → AssemblyScript, Grain (Route B)
→ MoonBit (Route C). This also moves from "wasm is a target of a systems language" to
"wasm-first with own runtime".

### 2.6 Synthesis
- One consolidated matrix: concepts × languages, cells = exposure level + citation key.
- Findings, each tied to evidence in 2.5:
  1. Where in the stack exposure is decided (route, not language syntax).
  2. Memory is the weakest area (implicit or runtime-owned almost everywhere).
  3. Module-level entities (globals, tables, tags) are rarely language items.
  4. Boundary safety is the same everywhere: integers and pointers.
  5. Escape hatches substitute for design: each language solves "need an instruction we
     don't expose" with a different back door.
- What a designer who wants fuller exposure would have to decide (the design questions
  chapter 3 answers). **No wx syntax here**, only the questions.

### 2.7 Summary and transition to Chapter 3

## 4. What this removes from your old chapter 2 / `plan.md` §2
- The long generic Wasm primer shrinks to 2.1–2.2; keep only facts later chapters use.
- Sandbox is told once (2.1) as planned in `plan.md`.
- The extensions survey stays but is reframed around "what changes for languages".
- Related work stops being "four languages on memory" and becomes five languages across
  all module entities, which is what Chapter 1.2 actually claims (memories, globals, tables,
  imports, exports, tags).
- **Tension to resolve:** `plan.md` §2 lists AssemblyScript, Zig, Grain, MoonBit; this chapter
  adds Rust. Chapter 1 never names languages, so no conflict, but `plan.md` should be updated.

## 5. Fact-checking protocol (so every claim is defensible)

Three evidence tiers, each claim labelled by the strongest tier it has:
1. **Spec/primary:** WebAssembly core spec, proposals repo, tool-conventions, language
   reference docs, compiler source. Cited by URL + version/commit + access date.
2. **Experiment:** a minimal program in each language, compiled, inspected with
   `wasm-objdump`/`wasm2wat` (both installed), to confirm what is actually emitted
   (e.g. is the memory exported by default? what does an import look like in the binary?).
   Kept in a `chapter-2-experiments/` directory so results are reproducible.
3. **Secondary:** blog posts and issue threads. Allowed only for *limitations*, and always
   corroborated or flagged.

Rules:
- Every statement of the form "language X cannot do Y" needs either an experiment or a
  cited statement from the language's own docs/maintainers. Absence in docs is not evidence.
  This is the highest-risk class of claim in the chapter.
- Pin versions: Rust, Zig, AssemblyScript, Grain, MoonBit are all moving (Grain and MoonBit
  especially). State the version tested for each.
- Keep a claims ledger (`chapter-2-claims.md`): claim, tier, source, verified date, status.
  Items from my earlier research summary marked † are all entered as **unverified**.

Tooling available here: `rustc` + wasm targets, `wasm2wat`, `wasm-objdump`, `wasmtime`,
`node`, `deno`. **Not installed:** `zig`, `asc` (AssemblyScript), `grain`, `moon`. Experiments
for those four need installs (all are available without root; I'd do it only with your OK).

## 6. Decisions I need from you
1. **Exposure ladder vs neutral spectrum** (section 2 above).
2. **Rust as a full case study** (my recommendation: yes, it is the reference point for
   Route A and has the most mature interface layer).
3. **Experiments for all five languages?** (recommended; needs installs) or cite-only for
   those not installed.
4. **Scope of the extensions section** (2.3): compact table (recommended) or a full
   subsection per proposal.
5. **Optional contrast language** using Wasm GC as its native model (Kotlin/Wasm, Dart/Flutter,
   or OCaml `wasm_of_ocaml`), as a half-page counterexample to "memory is runtime-owned".
   Not in your list, so default is no.

## 7. Proposed order of work
1. You decide section 6.
2. Build the claims ledger and run experiments (Rust first, it needs no installs).
3. Write 2.1–2.3 (pure Wasm facts, checkable against the spec).
4. Write 2.4 and the case studies, one language at a time, each followed by a fact-check pass.
5. Write 2.6–2.7 last, once the matrix is filled from verified cells.
