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
3. **Language design** — the thesis's narrative spine (see 2026-09-30 framing above): syntax +
   type system rationale for *shipped* (or landed-on-`tir-refactor`) mechanisms, organized
   around *why wx's design fits wasm specifically* — memory-tagged/ownership-sigiled pointer
   types, `memory`/`global` declarations resolving to compiler-synthesized `Memory`/`Global`
   trait impls, `#[intrinsic]` as a visible (not buried) boundary to raw instructions. Every
   claim here should be evidenced in ch. 4. Regenerated grammar (or curated version) as an
   appendix.
4. **Implementation** — rewrite of `implementation.md` covering the current pipeline in full
   (generics/monomorphization, traits, modules/privacy, `match`, the scheduler cross-branch
   fix). Framed explicitly as *evidence* for chapter 3's shipped claims, not a parallel
   narrative of its own.
5. **Effect tracking (WIP design chapter)** — decided 2026-09-30: its own short chapter, not a
   subsection of ch. 3, since it is genuinely unimplemented (zero compiler code) rather than
   landed-but-unreleased like ch. 3's material. Opens with an explicit "designed, not
   implemented" statement, then earns its place by showing it *isn't* a bolted-on separate
   system: it's planned to reuse ch. 3's own machinery — bodyless `#[intrinsic]` functions as
   effect origins, the `Mem`/`G` generic parameters from the Memory/Global-as-traits mechanism
   doing double duty as effect parameterization (`write<Mem>`), and resolution hooked into the
   same `ensure_signature`/`sig_state` demand-driven machinery every other signature already
   goes through. See [[thesis-framing-hybrid]] and the `notes/` completion-status entry above
   for which doc's syntax is current (`effect-tracking-plan.md`'s bracket clause, not
   `effect-system.md`'s `does(...)`).
6. **Tooling & ecosystem** — LSP, formatter, editor integrations, npm/release pipeline,
   the self-hosted WASM playground. Keep this chapter light — evidence of polish, not the
   intellectual core being graded.
7. **Evaluation** — testing methodology, example programs, and an honest limitations section
   that explicitly reconciles with chapter 3: which design-chapter claims are shipped-and-
   tested vs. landed-but-not-yet-recompiling (this branch's disabled MIR/opt/codegen), stated
   plainly rather than left implicit.
8. **Conclusion & future work** — what's left *beyond* chapters 3 and 5 (ownership/borrowing if
   not given its own treatment, plus genuinely smaller open items — simd, task, todos).

**`thesis/plan.md` (created 2026-09-30) is the live, section-by-section working outline** —
this file (`context.md`) stays the decision log and source map (why things are the way they
are, dated design-evolution notes, versioning/citation discipline); `plan.md` is what to
actually write, in order. Keep them in sync: when a structural decision changes here, mirror
it there, and vice versa.

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
- Effect tracking — **zero lines of compiler code** (re-verified 2026-09-30: no `does`/bracket
  effect-clause parsing, no `Effect`/`EffectSet` type, no `tag`/`catch` keyword anywhere in
  `crates/wx-compiler/src`), but ~2500+ lines across four docs represent real design-*and*-
  implementation-planning depth, not just a wishlist. **Reading order / authority, by actual
  git date** (corrects an earlier, slightly-off note guessing the syntax switch happened
  2026-09-04 — it didn't, see below):
  1. `effect-system.md` (869 lines, commit `c4f21d1`, 2026-08-11) — the original model: effects
     as sets, `does(...)` spelling. **Its syntax is superseded** — kept as "alternatives
     considered" / motivating-model material, not a citation source for current syntax.
  2. **`post.md` (788 lines, commit `e895c3b`, 2026-09-02) — the best thesis seed.** A
     polished, externally-publishable write-up already structured as a pedagogical arc: wasm's
     sandbox model → why signatures need effects → effect origin via self-referencing bodyless
     functions → composition/inference through the call graph → trap tracking → **exceptions**
     (`tag`/`Tag`/`Exception` traits, `throw<E>`, `catch` with exhaustiveness checking, mirroring
     `match`'s exhaustiveness) → memory effects (`read<Mem>`/`write<Mem>`/`grow<Mem>`,
     parameterized by the memory's own unique type) → effect polymorphism through traits/generics
     (upper bounds, abstract effects like `<V as Validator>::validate` before monomorphization,
     default-impl checking, dynamic dispatch forced to `[*]`) → public-API-boundary annotations
     → globals via `Global`/`GlobalMut`. This is what settled bracket syntax (`[trap]`, `[*]`,
     `[]`) on **2026-09-03**, per `effect-tracking-plan.md` §0's own dated note — one day after
     `post.md`, not 09-04.
  3. `effect-tracking-plan.md` (1610 lines, v3 dated 2026-09-04, commit `e67768a`) — the
     **implementation-mechanics plan built on top of `post.md`'s model**: pins resolution to a
     real hook (Phase 2's `ensure_signature` in `tir/builder/signature.rs`, reusing the same
     demand-driven, re-entrancy-safe `sig_state` machinery every other signature resolves
     through), works out the effect-scope-forest construction, solver staging, and wildcard
     arguments (`throw<_>`). Good source for an "implementation sketch" subsection, not for the
     conceptual exposition — `post.md` already did that better.
  4. `effect-tracking-implementation-ideas.md` + a working-draft file — supplementary.

  **Design-evolution thread, confirmed by the author 2026-09-30**: `post.md` (Sept 2) proposes
  verbose, explicit trait-bound declarations —
  `memory heap: Memory where { Size = u32 };` / `global x: GlobalMut where { Value = i32 } = 0;`.
  The author has **since changed their mind on this specifically** — the general principle now
  preferred is: derive the trait bound from the plain type wherever the compiler can, rather
  than spelling it out, because it's both simpler to parse and easier to read. `cd3c927`
  (2026-09-27) already ships this for Memory/Global: `memory heap: u32;` / `global mut x: u32 =
  0;`, compiler-synthesized impl, no `where` clause at all. **When drafting examples for the
  thesis, always use the current derived-bound form, never reproduce `post.md`'s `where { ... }`
  syntax as if it were current** — cite it explicitly as the superseded proposal in a "design
  evolution" aside if useful, but don't let it leak into example code elsewhere.

  This principle is narrower than it first sounds — it's about a *concrete declaration*
  restating an associated-type binding a plain type annotation already implies, not about
  `where` in general. **Corrected 2026-09-30**: I initially (wrongly) cited `post.md`'s `tag`
  declaration as a second example needing this treatment — it isn't one. `tag
  ApplicationError(status: ErrorStatus) -> never;` has no `where` at all; `Tag::Result` is
  already derived from the trailing `-> never`. The `where` that *does* appear nearby,
  `trait Exception: Tag where { Result = never }`, is an ordinary supertrait bound on a trait
  *definition* (constraining what any `Tag`+`Exception` impl must share) — a different, still-
  current use of `where`, not the pattern being phased out. Don't flag every `where` sighting in
  the effects material; check whether it's a concrete declaration's derivable associated type
  versus a genuine cross-trait bound first. See [[wx-derive-bound-from-type]].
  - [[thesis-framing-hybrid]]: decided 2026-09-30 this gets its **own short WIP chapter**
    (not a subsection folded into the language-design chapter), but the chapter must draw the
    explicit connecting thread back to what *is* shipped: every effect atom is planned to
    piggyback on the same bodyless-`#[intrinsic]`-function representation wasm instructions
    already use (`store_i32<Mem: Memory>(...) does(write<Mem>, trap)`), and the same `Mem`/`G`
    generic parameter the Memory/Global-as-traits mechanism (`cd3c927`) introduced does double
    duty as the effect's own parameterization (`write<Mem>`). That reuse is the argument for why
    this is a coherent design extension rather than a bolted-on separate system — cite it, don't
    just assert it.
  - Pairs naturally with the two ownership/borrowing devlog entries
    (`devlog/2026-08-11-ownership-*.md`) as adjacent WIP-chapter material.
- `simd.md`, `task.md`, `todos.md` — smaller, unimplemented items, stay in the closing
  future-work chapter rather than the new effect-tracking WIP chapter.

**Rejected — kept for the record**:
- `type-expression-escape-syntax.md` — explicitly `Status: REJECTED`, reasoning preserved.
  Good "considered and rejected alternatives" material — shows deliberate judgment, not
  just accretion.

**Stale as a source — don't cite for current state**:
- `notes/ONBOARDING.md` — describes a pre-refactor layout (root-level `std.wx`, single-file
  `tir.rs`/`mir.rs`, a `wx-wasm` crate) that no longer matches the repo.

## Version snapshot (revised 2026-09-30 — supersedes the v0.4.0 pin below)

**Decision 2026-09-30**: describe the **latest design direction**, not the last tagged
release — the `tir-refactor` branch is expected to land and ship (as a tagged version) before
the thesis is submitted, so pinning to `v0.5.0` (2026-09-05, the tag at the time this decision
was made) would describe something already superseded by publication time. Concretely: cite
the newest *design* landed on `tir-refactor` (e.g. the Memory/Global-as-compiler-synthesized-
traits mechanism, commit `cd3c927`, 2026-09-27) as the thing being described, not the older
`v0.5.0` `Memory`-trait-only version from the previous session's research.

This still needs the same falsifiability discipline the old pin gave for free, just done by
hand instead of by tag:
- **Cite a commit hash + date** for anything described from `tir-refactor`, not "current
  behavior" — e.g. "as designed as of commit `cd3c927` (2026-09-27)."
- **State implementation status explicitly per feature**, since this branch has MIR/opt/
  codegen/builder deliberately disabled mid-refactor (see [[tir-refactor-state]]): a
  TIR-level, type-checked-and-tested claim ("380 TIR tests pass") is not the same as "compiles
  to wasm," and the thesis text must say which one it's claiming.
- **Re-verify against the branch right before submission** — if `tir-refactor` has landed and
  tagged by then, re-cite the real tag; if a described mechanism changed shape before
  submission, the thesis text needs a pass to match, since "latest design" is a moving target
  in a way "last tagged release" deliberately wasn't.

Superseded original (2026-08-12): the compiler is under active development (ownership/
borrowing and effect-system design are both still exploratory, see `devlog/`). Describe the
implementation as of a fixed version — v0.4.0 (last tagged release as of 2026-08-12) — rather
than "current."

## Purpose and framing (revised 2026-09-30 — supersedes the framing below)

**Hybrid framing, decided 2026-09-30**: language **design** is the narrative spine — the
central thesis claim is that wx's type system reifies WASM's linear-memory / multi-memory
model as first-class, ownership-typed constructs (see the design-narrative candidates below),
rather than treating wasm as an opaque compile target the way AssemblyScript/Grain/MoonBit do.
Every claim about a *shipped* feature must still be backed by the real pipeline/tests as
evidence it works — don't drop the engineering rigor, just don't let implementation coverage
be the organizing principle. The effect system (and ownership/borrowing) get real space
*inside* the design chapter, not exiled to a two-paragraph future-work mention — but every
mention must be explicitly and repeatedly labeled "designed, not implemented" (mirroring how
the Effekt LSP thesis handles a real effect system at the "designed" level), and the
evaluation chapter must still honestly state what does and doesn't run.

**Core uniqueness argument to build the spine around**: existing wasm-targeting languages
either (a) port an existing GC'd/single-heap model onto wasm and hide linear memory entirely
(AssemblyScript, Grain, MoonBit), or (b) are systems languages retrofitted to also emit wasm
without adapting to wasm's own extensions — multi-memory, memory64 (Zig). wx's contribution is
designing the type system *around* wasm's actual affordances: memory as a first-class,
multiply-instantiable, ownership-typed resource (pointer/slice/array types carry an explicit
`memory: TypeIndex`, e.g. printing as `heap::&[u8]`), plus a structurally verified guarantee
(codegen tests) that no wasm-extension encoding (multi-memory index prefixes, memory64 limit
flags) is emitted unless the program actually uses that feature. See
[[wasm-extensions-incremental]].

**Original framing (2026-08-12), now superseded by the above but kept for context**: this is a
bachelor's **engineering** thesis, graded on: does it work (tests, examples), are decisions
justified (not just described), is there depth on CS fundamentals (type checking, IR design,
monomorphization, dispatch), and is there honest self-evaluation (a real limitations section,
not an afterthought). Favor "we considered X, rejected it because Y" prose over feature-list
prose wherever the source material supports it — it usually does, see `notes/` and `devlog/`
above.

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
