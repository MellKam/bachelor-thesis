# CLAUDE.md — thesis/

Context for AI assistants working on the bachelor's thesis in this folder. Supplements
the root `CLAUDE.md` (which documents the wx compiler itself) — that one is authoritative
for the project's current technical state; this one is authoritative for how the thesis
itself is being written and what's been decided so far.

## Tooling: Typst, not Markdown or LaTeX

The thesis is written in [Typst](https://typst.app). Deliberate choice over Markdown
(no native citations/cross-refs/figure numbering — would need Pandoc→LaTeX anyway) and
over raw LaTeX (heavier syntax, opaque errors, slow compiles). Typst is still plain-text
`.typ` source, so treat it like any other source file: read/edit directly, and verify
changes by actually compiling, not by eyeballing the markup.

- Compiler: installed via `brew install typst` (v0.15.1 as of 2026-08-12).
- Compile: `typst compile <file>.typ <file>.pdf`. Live preview while editing:
  `typst watch <file>.typ <file>.pdf`.
- The user has the Typst VS Code extension (Tinymist) installed for in-editor preview.
- Typst's compiler errors are structured and point at exact spans — read them and fix
  directly rather than guessing; confirmed working on the first real error hit
  (a `cannot reference heading without numbering` error, fixed by adding
  `#set heading(numbering: "1.")`).
- Polish diacritics, `#set text(lang: "pl")` hyphenation, and `#set page(paper: "a4")`
  all verified working with the default font — no missing-glyph or hyphenation-dictionary
  issues.

## Language plan

- Primary writing language: **English**.
- A **Polish translation is planned as a real second version** later, not a stub.
- Agreed structural approach for when that starts (not yet built): a shared template
  function parameterized by language (title page, heading/page styling), with separate
  chapter source per language (`chapters/en/`, `chapters/pl/`) and two thin entry points
  (`main-en.typ`, `main-pl.typ`) that each set the right `lang` and include their own
  chapters. Goal: translating later is "copy chapter files, translate prose," not
  rebuilding structure — both versions independently buildable at any time.

## Formatting / template

- **No university-mandated template confirmed yet** (as of 2026-08-12). Use sensible
  defaults (A4, standard single-column academic layout) until the user checks with their
  department/supervisor.
- Once a required template is known (often distributed as a LaTeX class or Word template
  elsewhere), replicate its rules — margins, title page, fonts, required front-matter like
  a Polish *streszczenie*/*oświadczenie* — inside the shared template function, not
  scattered per-chapter.

## Current state of `thesis/` (as of 2026-08-12)

- `history.md` — Polish-language background/motivation content (JS's problems, Native
  Client, asm.js). Solid as content; still needs porting into Typst.
- `implementation.md` — an early Chapter 4 draft (English). Describes the pipeline as it
  looked when the LSP had *just* landed — predates structs, traits, generics, modules,
  `match`, `typeset`, WASI support, and more. **Needs a substantial rewrite, not a
  straight port.**
- `grammar.ebnf` — similarly stale; has no structs/traits/generics/modules/attributes/
  `match`. Needs regenerating from the current parser before use as an appendix.
- `hello.typ`/`hello.pdf` — first Typst smoke test, confirms the toolchain end to end.
  Safe to delete once real content exists.

## Recommended thesis structure (discussed, not yet built)

1. **Introduction** — port/trim `history.md`, add explicit goals/non-goals + contributions.
2. **Background** — WASM itself (not just "why not JS"), plus a short comparison to other
   WASM-targeting languages (AssemblyScript, Zig, Grain, MoonBit) to justify a new language.
3. **Language design** — syntax + type system rationale, separate from implementation;
   regenerated grammar (or a curated version) as an appendix.
4. **Implementation** — rewrite of `implementation.md` covering the current pipeline in
   full (generics/monomorphization, traits, modules/privacy, `match`, the scheduler
   cross-branch fix).
5. **Tooling & ecosystem** — LSP, formatter, editor integrations, npm/release pipeline,
   the self-hosted WASM playground. Keep this chapter light — evidence of polish, not the
   intellectual core being graded.
6. **Evaluation** — testing methodology, example programs, an honest limitations section.
7. **Conclusion & future work** — ownership/borrowing + effect-system design (see below).

**Recommended spine**: the pipeline architecture as backbone, plus 2–3 deep "design
narrative" dives rather than exhaustive feature coverage. Best dive candidates, in order:
- Trait dispatch / "one impl per type constructor" rule — full decision trail exists (see
  `notes/` below), including a rejected-then-refined discussion with an LLM and a shipped
  result with tests.
- The TIR `Place`/`Value` split — explicitly modeled on Rust's HIR/THIR/MIR split, motivated
  by two concrete bugs. Good vehicle for showing *why* a compiler adds an IR layer.
- `typeset` — a real, shipped, slightly novel type-system feature (closed compile-time type
  sets), not just a copy of an existing language's mechanism.

**Minimize**: editor integrations, npm publishing mechanics, playground internals — mention
as "exists and works" with a screenshot/link, don't write pipeline-depth chapters on them.

## Source material map — where to find "why", not just "what"

- Root `CLAUDE.md` — authoritative for current project state. Trust this over
  `thesis/implementation.md` or `notes/ONBOARDING.md` (the latter is itself stale).
- `CHANGELOG.md` — feature timeline, one entry per release; good for "when did X land."
- `devlog/` — session-by-session narrative of what was built and why, with an `index.md`
  summary. Primary source for design-rationale prose.
- `notes/` — design docs and plans, **mixed completion status** — see below. Primary source
  for "alternatives considered" and future-work material.

## `notes/` completion status (verified against code on 2026-08-12 — not just doc headers)

**Implemented / shipped** — safe to describe as current behavior:
- `typeset.md` — implemented as designed (`pub typeset Integer {...}` etc. live in
  `std/main.wx`).
- `tir-place-value-split.md` + `-plan.md` — DONE, 518/518 tests.
- `generic-trait-impls-plan.md` — DONE (CHANGELOG 0.2.0).
- `single-trait-impl-per-constructor-plan.md` + `chatgpt-multiple-trait-implementations-per-target.md`
  — DONE (CHANGELOG 0.2.0). The ChatGPT transcript is genuinely good primary-source design
  rationale — working through the Rust-precedent tradeoff before committing.
- `enum-validation.md` + `-plan.md` — DONE, verified line-by-line against `tir/builder.rs`
  (all 7 validation items, plus the `build_const_expression` → `eval_const_expr` architecture
  pivot). The doc itself has no "DONE" header unlike its siblings — don't be misled by that.
- `trait-dispatch-followups.md` — core ambiguity fix DONE; a specific, named punch list of
  remaining gaps is still open (span precision, cross-block duplicate detection, hot-path
  allocation) — good "known limitations" material.

**Partially implemented / contains stale claims** — verify before citing:
- `intrinsics.md` — describes an `fn @name()` intrinsic syntax that was **abandoned**;
  current reality is `#[intrinsic]` attributes (confirmed via grep on `std/main.wx`, zero
  `fn @` occurrences).
- `incremental-lsp.md` — Phase 1 (parse cache) done, Phases 2–3 (per-file AST cache,
  salsa-style incremental TIR) not started. Also references a `wx-lsp-next` crate name that
  no longer exists anywhere in the tree (consolidated into `wx-lsp` per root `CLAUDE.md`).

**Not implemented — genuine future-work material**:
- `effect-system.md` — extensive, fully-worked design (confirmed: zero `!(` effect syntax
  anywhere in `std/main.wx`). Best future-work chapter material; pairs naturally with the
  two ownership/borrowing devlog entries (`devlog/2026-08-11-ownership-*.md`).
- `simd.md`, `task.md`, `todos.md` — smaller, unimplemented items.

**Rejected — kept for the record**:
- `type-expression-escape-syntax.md` — explicitly `Status: REJECTED`, reasoning preserved.
  Good "considered and rejected alternatives" material — shows deliberate judgment, not
  just accretion.

**Stale as a source — don't cite for current state**:
- `notes/ONBOARDING.md` — describes a pre-refactor layout (root-level `std.wx`, single-file
  `tir.rs`/`mir.rs`, a `wx-wasm` crate) that no longer matches the repo.

## Version snapshot

The compiler is under active development (ownership/borrowing and effect-system design are
both still exploratory, see `devlog/`). Describe the implementation as of a **fixed
version — v0.4.0** (last tagged release as of 2026-08-12) — rather than "current," and say
so explicitly in the thesis text, so nothing in it can be falsified by a later commit.

## Purpose and framing (agreed direction)

This is a bachelor's **engineering** thesis, graded on: does it work (tests, examples), are
decisions justified (not just described), is there depth on CS fundamentals (type checking,
IR design, monomorphization, dispatch), and is there honest self-evaluation (a real
limitations section, not an afterthought). Favor "we considered X, rejected it because Y"
prose over feature-list prose wherever the source material supports it — it usually does,
see `notes/` and `devlog/` above.

## Reference theses (structural inspiration, not content)

Found via web search 2026-08-12, not fully read — check each one's actual structure before
modeling a chapter on it:

- Lund University Master's Thesis 2025, *"Compiling automation programming languages to
  WebAssembly"* — closest topical match (compiler → WASM), full thesis structure to mirror.
- DiVA, *"Designing an Introductory Programming Language"* (bachelor's) — strong
  language-design-rationale chapter template.
- Universität Tübingen, Neumann bachelor's thesis — LSP implementation for *Effekt*, a
  language with a real effect system. Template for the tooling chapter, and directly
  relevant to how a thesis presents an effect-system design at the "designed, not fully
  core" level.
- [github.com/nr23730/bigdata-wasm](https://github.com/nr23730/bigdata-wasm),
  [github.com/AndreaEsposit/bachelors-thesis](https://github.com/AndreaEsposit/bachelors-thesis)
  — closest peer bachelor's projects (own language/compiler targeting WASM).
- Harvard DASH, *"WebAssembly as a Multi-Language Platform"* — more advanced; useful
  register for the type-system chapter if it needs to get formal.
