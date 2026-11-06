# Chapter 2 — sketch (structure and argument, not prose)

Status: rough sketch. Replaces `chapter-2.md` (old four-language plan) and merges
`chapter-2-outline.md` with `chapter-2-draft.md`. Section numbers here are the new ones.
Facts in the results sections come from `wasm-exposure-study/` (snapshot of 2026-10-02).

## The job of this chapter

Chapter 1 claims that each language builds on only part of the platform, so using all of it
means combining languages. This chapter has to earn that claim with evidence, and narrow it
wherever the evidence is weaker. It is not a Wasm tutorial and not a language survey.

One-sentence story:

> WebAssembly offers a fixed set of declared entities. Languages reach them unevenly, the
> gaps cluster around memory and module-level entities, and where a language stops, the
> programmer is left with an integer address or an escape hatch.

Rules for the prose (from the review):

- Describe, don't judge. Judgement only in 2.6.
- Reachability from source, not language quality. Hiding Wasm is a goal for some of these languages.
- "Not found" is not "impossible." Say which one in every summary sentence.
- Every section must set up vocabulary Chapter 3 uses or support a finding. Otherwise cut it.
- One term per idea (construct = language side, entity = Wasm side). No dash-heavy sentences.
- No wx syntax. End with questions, not answers.

## Section plan

| § | Title | Purpose | Budget |
|---|---|---|---|
| 2.1 | The module surface | Vocabulary: entities, index spaces, imports and exports, the sandbox. One WAT example reused later. | 2 pp |
| 2.2 | Execution model and extensions | Only facts that change a compiler's job. Extensions as a compact table: multi-memory, memory64, GC, exception handling (`try_table`), stack switching. Dated. | 2–3 pp |
| 2.3 | How the languages are compared | Locus codes (N/A/C/E/X), the probes, the capstones, versions, limits of the evidence. State criteria before any result. | 1.5 pp |
| 2.4 | Results by concept | Matrix, then one subsection per finding (below). | 4–5 pp |
| 2.5 | Why the results look like this | Three routes (LLVM and linker, Binaryen-style direct emission, custom backend) and the interface layers. Language profiles reduced to a few lines each; the long ones go to an appendix. | 2 pp |
| 2.6 | Synthesis and design questions | What a designer would have to decide. | 1.5 pp |

2.4 is organised by concept, not by language: the argument is about patterns across languages.

## 2.1 The module surface

- Module: types, functions, tables, memories, globals, tags; imports, exports, start function,
  segments, custom sections. Separate index spaces.
- Binary vs WAT vs embedder. WAT example: import, call, export.
- Sandbox told once: no ambient authority; imports can still grant a lot; WASI is a host
  interface, not core Wasm.
- Closing sentence: this list is what a developer might want to name. That sets up "reach".

## 2.2 Execution model and extensions

Facts only, each with one "so what for a language" sentence:

- Typed stack machine and validation.
- Structured control flow (block expressions, labeled break).
- Linear memory is untyped bytes; a pointer is an integer; bounds-checked, no safety inside a module.
- Multiple memories as separate indexed stores. Also state here that each kind of entity has
  its own index space (function 0 and memory 0 are unrelated); it was cut from 2.1.
- Globals (more space; wx exposes them) and tables (one paragraph, indirect calls only).
- Traps vs exception handling with tags; multi-value and calling conventions.
- Extensions table: feature, fact, why it matters to a language. Group by what changes
  (more memory, more value kinds, more control). Check status against the proposals repo
  before writing, and date it.

## 2.3 How the languages are compared

- Languages: Rust, Zig, AssemblyScript, Grain, MoonBit. Pinned versions in a table.
- Locus codes: N language construct, A annotation, C build configuration, E escape hatch,
  X not achievable (`*` partial, `‡` nightly only, "unresolved" weaker than X). Neutral, no ranking.
- Method: twelve probes read from the compiled binary, not from docs; two capstones
  (Game of Life, WASI `cat`) on one shared host.
- Criteria stated up front: **reach** (can the construct be produced from source) and
  **control** (can the programmer choose, e.g. a memory's name and limits).
  **Not measured:** boundary safety (hypothesis H5), build time, idiomatic ecosystem layers.
- Fairness paragraph: raw builds are each language's floor; AssemblyScript, Grain and
  MoonBit capstones were written at their lowest layer, which biases the pointer finding.
  Say so here, once.

## 2.4 Results by concept

Opening: the matrix from the draft, plus one line on what is **not** a gap
(imports and exports are well exposed in all five). This is the honest narrowing of Chapter 1.

| # | Finding | Evidence | Status |
|---|---|---|---|
| F1 | No language declares a memory. It exists implicitly and is configured by flags or a config file; only MoonBit lets the build file choose the exported name and import module and field. | P2, P3 | measured |
| F2 | No type ties an address to a memory. Rust and Zig have typed pointers, AssemblyScript, Grain and MoonBit use `i32` addresses, none relates a pointer to the memory it points into. | capstones, 2.4.3 of the draft | measured, with the floor-layer caveat |
| F3 | Module-level entities are rarely language items. Globals only in AssemblyScript; tables only as a by-product of function pointers; tags in none; multi-value and multiple memories in none. | P4–P9 | measured |
| F4 | What you write is not what you get. Unrequested import (AssemblyScript `env.abort`), optimizer removing a SIMD add or a table lookup, large baselines (Grain 3,650 bytes, 20 globals). | P5, P11, P12 | measured |
| F5 | Each language commits to one memory model per build. Linear memory with manual control (C++, Rust, Zig), reference counting in linear memory (Grain, MoonBit `wasm`), host GC (MoonBit `wasm-gc`, Kotlin/Wasm). Combining models usually means combining languages. | docs, not the probes | **cited, not measured** — the study did not probe `wasm-gc` |

Notes:

- F5 is the chapter's link back to the Chapter 1 diagram. It is the only finding that rests
  on documentation. Label it that way, and use only languages whose docs are cited.
- The Component Model sentence goes here or in 2.6: components join separately written pieces,
  but each piece is still written inside one language's model.
- Size numbers and the 76 KB vs 360 B `cat` comparison: keep only if they support F4.

## 2.5 Why the results look like this

- Route A, LLVM objects and `wasm-ld` (Rust, Zig): entities appear as symbols and linker flags,
  hence much configuration (C) and attributes (A). Several gaps are toolchain limits, not design:
  the single-memory limit is in the linker.
- Route B, direct emission (AssemblyScript, Grain): the compiler owns the module, so it can
  expose globals and start, but brings its own runtime and value model.
- Route C, custom backend (MoonBit): multiple backends chosen by build flag.
- Interface layers (C ABI, `wasm-bindgen`, WASI, WIT): explain once, as a layer on top of
  any route and not part of the language. Verify the Binaryen claims before writing.
- This answers the "paradigm or toolchain" objection from the review: say plainly which gaps
  are design and which are unimplemented proposals.

## 2.6 Synthesis and design questions

- Pull F1–F5 together in a short paragraph each.
- Three questions for Chapter 3, each traceable to a finding:
  1. Can a pointer identify which memory it addresses? (F1, F2)
  2. Can memories, globals and other entities be declared in source and take part in ordinary
     generic constraints? (F1, F3)
  3. Can the module boundary stay visible while the language provides safer operations? (F4)
- No wx declarations here.

## Visuals

1. WAT import and export example (2.1).
2. Matrix of results (2.4), using the locus codes.
3. The Chapter 1 diagram, redrawn: platform circle, language circles labelled by memory
   model, and one feature (multiple memories) that sits in no circle. Do not draw wx as covering everything.
4. Two indexed linear memories beside a separate GC heap (2.2).

## Retire from the old plans

- The generic Wasm primer, the per-language fixed template as the main section, the
  "naturalness" criterion, the 0–5 ladder, and the "boundary safety is the same everywhere" finding (untested).
- Keep from `chapter-2.md`: the Zig caution (it accepts a memory index, so don't say it has no multi-memory support),
  `try_table`, the tone rules, the transition questions.

## Open decisions

1. Run the same twelve probes on wx? It makes the comparison fair and shows wx's own gaps, at the cost of real work. Decide before 2.4 is written.
2. F5 evidence: is citing docs for the GC side enough, or probe the MoonBit `wasm-gc` backend?
3. Which examples fill the GC side of the diagram: Kotlin/Wasm, Dart, or MoonBit `wasm-gc`? Pick ones with citable docs.
4. Where the long language profiles go: appendix, or cut.
5. Update `plan.md` §2 to match (five languages, results by concept).
