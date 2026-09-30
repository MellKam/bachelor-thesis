# Thesis outline — working plan

Bottom-up arc: start from WebAssembly's own execution model, then show each wx design
decision as a deliberate answer to "how much of this do we expose, and how." Every section
should earn its place by pointing back at a WASM property it's representing, extending, or
deliberately declining to hide. Framing/versioning discipline (hybrid design-first, cite
`tir-refactor` commit+date, evidence per claim) lives in `context.md` — not repeated here.

## 1. Introduction

Short — a fast, argument-only read. No deep WASM technical content here; that's Chapter 2's
job. Standard funnel shape: hook → problem → thesis goal → contributions → scope → roadmap.

- **Opening hook**: the sandboxing/import example — a WASM module can do nothing outside its
  sandbox unless the host explicitly provides it (`console::log` as an import). Needs zero
  prior WASM knowledge to land, which is what a cold open should do. Adapt directly from
  `notes/post.md`'s own opening, which already has this well-written.
- **Problem statement**: existing WASM-targeting languages treat WASM as a compile target for
  a model imported from elsewhere — an existing GC'd runtime (AssemblyScript, Grain, MoonBit),
  or an existing systems-language memory model retrofitted to also emit WASM (Zig) — rather
  than designing around what WASM itself actually offers (multiple memories, an evolving set
  of typed extensions, a sandboxed import/export boundary).
- **Thesis goal**: can a language's type system directly reify WASM's own affordances —
  memory identity, exception tags, structured control flow — as first-class, generic,
  boundable constructs, using one recurring mechanism, rather than accreting a special form
  per feature?
- **Contributions**, as an explicit numbered list:
  1. A language design (wx) whose type system makes WASM memory/global/tag identity a
     first-class, derivable trait binding — verified against a working compiler for the
     shipped subset, not just described.
  2. A proposed extensibility argument: stack switching (an active WASM proposal) and GC
     (already standardized, but not yet implemented in wx) may build on mechanisms already
     present in the language design (Ch. 10). These remain design claims, not demonstrated
     compiler behavior.
  3. A fully worked, honestly-labeled-as-unimplemented effect-tracking design that reuses the
     same intrinsic-function representation as the rest of the language (Ch. 8).
  4. An honest account of what's shipped-and-tested vs. designed-only, and of the specific
     gaps found along the way — `as`-cast looseness, the struct positional-construction
     tradeoff, the init/effects conflict (Ch. 9).
- **Scope / non-goals**, stated explicitly: no full ownership/borrow-checking (sigils only,
  not a borrow checker), no GC/WasmFX implementation (future work only, Ch. 10), effect
  tracking is a design chapter, not a shipped feature — say this once here so nothing later
  has to hedge repeatedly.
- **Chapter roadmap**: one short paragraph mapping to Chapters 2–10 below.

## 2. Background

- WASM technical primer: stack-machine execution, module structure
  (types/functions/imports/exports/memories/globals/tables), single-pass typed validation,
  binary vs. WAT text format.
- The sandboxing property, told in full here (Ch. 1's hook only gestured at it): no ambient
  authority, everything crosses the module boundary explicitly via imports/exports. This is
  the motivating fact Ch. 8's effects chapter leans on — plant it here, don't re-derive it
  there.
- WASM's extension landscape survey: multi-memory, memory64, the exception-handling proposal
  (real spec vocabulary — `tag`/`throw`/`catch`, confirm wording against the spec before
  citing), briefly note the GC and stack-switching proposals (full treatment deferred to
  Ch. 10), and SIMD/tail-calls/threads as not yet addressed at all.
- **Related work**: AssemblyScript, Zig, Grain, MoonBit — what each actually does with WASM's
  memory model (single implicit GC'd heap; manual memory but not designed around WASM's own
  multi-memory extension as a language concept; etc.). This is what earns Ch. 1's problem
  statement — show it, don't just assert it.

## 3. Language design: wx's answer — unified, safe semantics

- Thesis statement for the whole design arc: rather than special-casing each WASM extension,
  wx exposes each as ordinary language constructs backed by one recurring mechanism —
  *derive a trait binding from a lightweight declaration instead of spelling it out*.
  Memory (`memory heap: u32;` → synthesized `impl Memory`), globals (`global mut x: u32 = 0;`
  → synthesized `impl Global`/`GlobalMut`), tags (`tag T(...) -> !;` → synthesized `impl Tag`)
  are three dated, concrete instances of the same pattern — name it once here, then just
  point back to it in §7 (memory/global) and §8 (tags) rather than re-arguing it each time.
- Extension-incremental codegen guarantee: no multi-memory/memory64 encoding emitted unless
  the program actually uses the feature, verified by the codegen test suite. "Pay for what
  you use," applied to spec proposals themselves.

## 4. Basics: functions and the stack

- Function declaration, calling convention, the stack-machine model underneath.
- **Block expressions as the value** (tail expression without `;`) — direct reflection of
  WASM's own typed block-result model. First "we represent this directly" example; say so
  explicitly rather than leaving it implicit.
- **Structured control flow**: labeled blocks, `loop`, `break :label value`, `continue` —
  WASM has no unstructured jumps, only nested `block`/`loop`/`br`/`br_table`. Most
  C-shaped source languages need a real CFG-reconstruction pass (relooper/stackifier-style)
  to target WASM at all; wx's source language never expresses irreducible control flow in
  the first place, so there's no such pass hiding in the pipeline. Brief mention of `match`
  → `br_table` as another instance, full treatment deferred to wherever enums/match land.

## 5. Values and expressions

- Untyped literals: `Type::Integer`/`Type::Float` as real placeholder types (pre-interned
  indices 4/5), forced annotation, **no default-to-i32** (deliberate departure from Rust —
  silently guessing a width has real, differently-encoded WASM consequences,
  `i32.const`/`i64.const`/etc. are different instructions). `{integer}`/`{float}` diagnostic
  spelling mirrors Rust's own convention — a borrowed-on-purpose detail.
- String literals as `&[u8]` — no dedicated string type, reuse over invention.
- `as` casts: explicit-only, no implicit widening. Forward-pointer only here; the honest
  limitations (`u32 as char` lossy, `&T as *T` ownership-erasing) belong in §9's evaluation,
  not here.
- `!` (bottom type, renamed from `never` — decided during this design pass, see devlog) and
  diverging expressions' interaction with block-value typing. Sets up the effects chapter's
  `-> !` usage without re-deriving it there. Note the considered-and-kept-as-sugar
  `type never = !;` alias idea.
- `const` vs `global`: compile-time-inlined value vs. real mutable module state — a
  distinction WASM itself already makes, not a wx invention.

## 6. Structs and the named-call-syntax generalization

- Struct declaration unification: paren-declared, named fields (`struct Point(x: i32, y: i32)`),
  replacing a separate tuple-struct/record-struct split.
- Positional and named construction as two faces of one mechanism — calling the implicit
  constructor. "Named call syntax" (`Point({ x: 2, y: 4 })`) generalizes to *any* function
  whose parameters are all named, not just structs — one more special form removed by
  expressing it as sugar over something that already exists.
- The `pub`-gates-positional-construction resolution: reuses existing field-visibility rather
  than inventing a new opt-in attribute. Named tradeoff, not a free lunch — say so.
- Flag honestly: **this is still-evolving design as of this writing**, not settled/shipped —
  don't overclaim status here.

## 7. Memory and globals: safe abstractions over WASM indices via ordinary trait dispatch

**Flagship uniqueness chapter** — the strongest concrete payoff of §3's thesis statement.

- Ownership-sigil'd pointer/slice/array types (`*T`/`&T`), each tagged with an explicit
  memory (`heap::&[u8]`) — multi-memory as a type-system citizen, not hidden behind one
  implicit heap.
- `Memory`/`Global`/`GlobalMut` as compiler-synthesized trait impls over a bare type
  declaration (`memory heap: u32;`, `global mut x: u32 = 0;`) — cite commit `cd3c927`
  (2026-09-27), landed after the last tag (`v0.5.0`).
- `Memory::INDEX: u32` exposing the raw WASM module index as an associated const.
- `memory_copy<Size, SrcMem: Memory, DstMem: Memory where { Size = Size }>(...)` — memory as
  a genuine generic parameter, one function over *any two* declared memories. No other
  WASM-targeting language in the comparison set can express this half of the argument.
- One-scalar-per-global restriction: type-checked by flattening the declared type to its
  underlying WASM value slots and rejecting anything but exactly one — reuses whatever
  flattening logic already backs multi-value returns/aggregate layout, rather than a new
  special case. Diagnostic should name both standard workarounds (split into multiple
  globals; store a pointer into linear memory instead).
- Global initializers: **constant-expression-only, no runtime/lazy initialization** —
  decided during this design pass after two real designs (a `lazy init` block, then a
  `#[start]`-attributed function) both ran into unresolved problems: combining multiple
  start-contributions has no natural deterministic order across files/modules, and
  meaningful startup work (allocator setup) is inherently memory-effectful, undermining the
  reason to want it in the first place. Good "considered, hit a real conflict with another
  in-progress subsystem, scoped back deliberately" material — cite it as exactly that, not
  as an oversight.

## 8. Effect tracking (WIP chapter — designed, not implemented)

Opens with an explicit "designed, not implemented" statement. Primary source: `notes/post.md`
(commit `e895c3b`, 2026-09-02) for exposition; `notes/effect-tracking-plan.md` v3 (2026-09-04)
for implementation mechanics; `notes/effect-system.md` (2026-08-11) only for
"alternatives considered" (superseded `does(...)` syntax).

- Motivation recap (one line, pointing back to §2's sandboxing property) → why a signature
  alone doesn't say what a function *does*.
- Effect sets as a lattice (`[]` bottom/pure, `[*]` top/unrestricted), origin via
  self-referencing bodyless functions, composition through the call graph.
- **The core architectural argument**: effects aren't a bolted-on separate system — every
  atom piggybacks on the bodyless-`#[intrinsic]`-function representation WASM instructions
  already use, and the same `Mem`/`G` generic parameter from §7's Memory/Global mechanism
  does double duty as the effect's own parameterization (`write<Mem>`,
  `global_get<G: GlobalMut>`). Resolution is planned to hook into `ensure_signature`
  (`tir/builder/signature.rs`) — the same demand-driven `sig_state` machinery every other
  signature already resolves through.
- Trap tracking as the base case.
- **Tags, introduced right here, immediately before exceptions** — not as an earlier
  standalone chapter. A tag is structurally just a struct, plus a derived associated type:
  `tag ApplicationError(status: ErrorStatus) -> !;` reuses §6's paren-declared field grammar,
  and the trailing `-> !` derives `Tag::Result` the same way `memory`/`global` derive their
  own associated types (§3's recurring pattern, third instance). Construction is identical to
  struct construction, because a tag *is* one. A bare tag is just a typed, constructible value
  — nothing throws or catches it yet. This belongs here rather than earlier because a tag on
  its own has no real payoff outside the effect-tracking story; unlike Memory/Global, which
  are useful independent of whether effects ever land, a tag's only interesting behavior is
  what `Exception` adds next.
- Exceptions as the interesting case because they can be handled: `Exception` as an explicit,
  non-automatic opt-in over `Tag` (a tag is a more general mechanism than "throwable"),
  `throw<E>`, `catch` with exhaustiveness — mirrors `match`'s exhaustiveness, another
  connecting thread.
- Memory/global effects parameterized by each instance's unique type.
- Trait/generic effect polymorphism: upper bounds on trait methods, abstract effects
  preserved pre-monomorphization (`<V as Validator>::validate`), dynamic dispatch forced to
  `[*]`, default-impl bound-checking, public-API-boundary annotation requirement.
- Honest open edge case: §7's global-initializer scope-back is a live example of this model
  not yet having an answer for "effects during a privileged initialization phase" — present
  as a genuinely open question, not resolved.
- Implementation status, stated plainly: **zero lines of compiler code** (verified — no
  effect-clause parsing, no `Effect` type, no `tag`/`catch` keyword in
  `crates/wx-compiler/src` as of this writing).

## 9. Current state of the implementation

- What's shipped and tested vs. landed-but-not-yet-recompiling (MIR/opt/codegen disabled
  mid-`tir-refactor`) — state the distinction plainly per claim, don't blur it.
- Testing methodology: `cargo test --workspace` counts, insta snapshots, `DiagnosticView`
  assertion vocabulary.
- Tooling in brief (LSP, formatter, editor integrations) — evidence of polish, not
  intellectual core; don't give this chapter-level depth.
- **Honest limitations section**, reconciling every earlier "shipped" claim against what
  actually compiles and runs today:
  - `as`-cast gaps: lossy casts (`u32 as char`) pass; pointer casts only compare `memory`,
    not ownership (`&T as *T` silently defeats read-only).
  - Struct positional-construction safety tradeoff from §6 (transposition risk on
    same-typed fields, mitigated only by choosing to keep fields private).
  - Effect system: fully unimplemented, plus the still-open init/allocation conflict.
  - Any other gaps surfaced while writing §4–§8 that didn't get flagged inline.

## 10. Conclusion & future work

- Ownership/borrowing (if not folded into an earlier chapter).
- Remaining effect-system open questions: multi-start-function ordering, init-time effects.
- **Extensibility argument, headline future-work material — not lumped with the smaller
  items below.** Two Wasm capabilities not yet addressed by wx (§2's survey) provide a
  design-level test of whether the architecture generalizes, and they land differently:
  - **The stack-switching ("WasmFX") proposal**, extending effect tracking toward genuine
    *resumable* effects. The current model only has two shapes for an effect firing: gone
    forever (`trap`) or unwound-to-a-catch-and-gone-from-there (`throw`/`catch`). Stack
    switching adds a third that effect systems normally treat as a different kind of thing —
    a handler captures a continuation it can invoke again, possibly more than once, which is
    what async/await, generators, and cooperative scheduling all reduce to. Be honest that
    this **revisits a stated non-goal**, not just extends the design:
    `notes/effect-system.md` explicitly says "Not an algebraic effect system — no handlers."
    Precise framing for the thesis: the *representation* (typed, composable, parameterized
    effect sets) is reusable as-is; the *handling* half (`catch`'s exhaustive-but-unwinding
    semantics) is not, and would need a `perform`/`handle`-shaped sibling, not a modification
    of `catch` itself.
  - **The GC proposal**, represented as another memory identity — `gc::&[u8]` reuses §7's
    memory-tag mechanism directly, since WASM's GC heap really is structurally "another place
    references live," the same move as multi-memory. The genuinely new piece: the current two
    ownership sigils cover exactly two points in ownership space (`*T` exclusive-and-owning,
    `&T` shared-and-borrowing), and a GC reference is a third — exclusive-for-safe-mutation
    but *not* owning, since the collector frees it, not the holder. This needs a `&mut`-shaped
    sigil the language deliberately doesn't have today ("there is no `.&mut`," per the root
    `CLAUDE.md`). Frame it as the same design move told a second time, not a new one: WASM's
    GC reference types are as untyped about exclusivity as linear-memory addresses are about
    ownership, so `&mut` here is a wx-added safety layer over a raw capability WASM itself
    leaves unconstrained — exactly the `*T`/`&T` story, applied to a structurally different
    memory kind. Note the cardinality asymmetry too: linear memories are zero-or-more and
    user-declared; `gc` would be zero-or-one and builtin, never declared by the programmer —
    doesn't break the mechanism, just adds a case to it.
- Smaller open items: simd, task, todos.
- Where the design is headed next.

---

## Notes on sourcing

- Design-evolution narratives worth citing with dates wherever they naturally occur (don't
  save them all for one "history" chapter): `!`-vs-`never` rename, `Exception`-not-automatic
  decision, the `memory`/`global` verbose-`where`-clause → derived-bound simplification, the
  global-initializer scope-back. These are what "decisions justified, not just described"
  looks like in practice.
- Anything cited from `tir-refactor` needs a commit hash + date, not "current behavior" — see
  `context.md`'s versioning section.
- Re-verify every code-adjacent claim against the branch again right before submission.
