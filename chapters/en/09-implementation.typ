#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote
#import "../../figures/architecture.typ" as arch

= Implementation and Tooling <ch:implementation>

The previous chapters described the language. This chapter describes the program that implements it. The compiler is one library, and everything else that works with WX source is a client of it; its type checker stays alive after checking, because later stages keep asking it questions; and it passes through several intermediate representations, each of which makes one problem small. The chapter ends with the testing methodology and an account of what does not work.

== Overview <sec:impl-overview>

The compiler is the Rust crate `wx-compiler`. The standard library is one WX file, embedded in the compiler when it is built. @fig:impl-pipeline shows the stages of a build and, under them, which stages each client of the library reaches. A build reads the packages (`vfs`) and parses them (`ast`), checks the whole program (`tir::check`), lowers the reachable functions into MIR (`tir::lower`), inlines (`mir::inline`), optimizes each function (`opt`) and encodes the module (`codegen`). The command line stops at the first stage that reports an error, so a syntax error never reaches the checker and a type error never reaches lowering.

#figure(
  arch.pipeline-figure(),
  kind: image,
  caption: [The stages of the compiler (top, with the product each hands to the next) and the clients of the library, each drawn as a bar over the stages it uses. A dashed bar is a client that is written but does not compile against the current type checker (@sec:impl-state).],
  placement: auto,
) <fig:impl-pipeline>

The figure shows the first decision. The formatter needs only the syntax tree, the language server needs the front end and the checker, and the backend tests need nothing before MIR. Each stage hands the next a plain data structure and none depends on its consumers, so a client can start or stop at any stage. That is why there is one compiler and not one per tool: a second implementation of name resolution for an editor would be a second place where the language is defined, and the two would disagree.

@fig:impl-size gives the size of each part. The checker is about two thirds of the compiler's production code; the backend, from MIR to bytes, is about a sixth.

#figure(
  arch.size-figure(),
  kind: "chart",
  caption: [Lines of live Rust, without comments and blank lines (`cloc`, 2026-11-06); tests include those inside source files. The standard library, in WX, adds about 2 000 lines.],
  placement: auto,
) <fig:impl-size>

== The front end <sec:impl-front>

Every compilation is rooted at a package, a directory with a `wx.json` manifest that names its entry file and its dependencies, and always includes the standard library. The lexer and parser are written by hand, and the parser reads expressions by operator-precedence (Pratt) parsing #fnote("pratt1973"); its syntax tree keeps the comments, which the formatter needs. All stages report through one diagnostic type, with source spans, labels and notes, and every client renders the same diagnostics for its own purpose: the command line prints them as text or JSON, and the tests assert on them.

== The checker: a live context <sec:impl-check>

The checker is the largest part of the compiler.

*Signatures on demand.* Declarations refer to one another in any order, so the checker computes a signature when it is first needed and not in source order, and it keeps the stack of queries so that a cycle is reported with the whole loop. Building a signature only turns the written syntax into types. The requirements it records are checked once every signature exists, and function bodies last, because only they need everything else. Two questions recur throughout: what an associated type or a constant in a type equals, and which impl applies to a type. One engine, the solver, answers both. It never reports a problem itself: the construct that wrote the type or the requirement owns the diagnostic, so a definition that depends on itself is reported once.

The checker's context is not frozen when checking ends. `tir::check` runs the checker, drops the context and returns the diagnostics. `tir::build` keeps the context, because lowering a generic function needs the checker's answers again (the normal form of a type, the layout of an aggregate, the impl a call selects), and returns MIR together with the diagnostics.

== From the checked program to bytes <sec:impl-lower>

Three representations follow the checker.

*Lowering and MIR.* The checked program is generic and the module is not, so lowering monomorphizes. It starts from the exports and the globals and lowers a function with its type arguments the first time something calls it, so an instance that nothing reaches is never built. The result, MIR, has the shape of WebAssembly: functions over scalar values, memories with their limits, aggregates with the byte offsets of their layout. A checked form that lowering does not cover yet is reported as unsupported and never dropped, so a missing case is an error and not a wrong program.

*Inlining.* The inliner splices small callees, callees marked `#[inline]` and callees with a single call site into their callers, and drops functions that nothing reaches. The standard library depends on it: the operators on primitive types are small functions marked `#[inline]` over intrinsics, so `a + b` on integers, which the type system treats as a call of a trait method, ends as one `i32.add` in the module.

*The optimizer.* For each function, a sea-of-nodes graph #fnote("click1995") is built, in which a computation is a node that depends only on its inputs and has no position, so identical computations are one node and a computation nothing uses is never emitted. A scheduler turns the graph back into instructions.

This backend is deliberately simple: it does not yet schedule for the stack, so modules come out larger than necessary (@sec:wx-comparison). This is a property of the optimizer and not of the language, since the typed result of each construct follows from the types.

== The tools around the compiler <sec:impl-tooling>

`wx` is one binary with `build`, `check` and `format`, and every command takes a directory with a `wx.json`. The formatter (`wx-fmt`) prints source from the syntax tree and needs no type information. The language server and the browser build of the library were written against the previous checker and are unfinished work (@sec:impl-state).

== Testing <sec:impl-testing>

Each stage is tested at its own boundary, with the input it receives and the output it hands on, and the tests of a stage run without the stages after it. @tbl:impl-tests lists the layers; the compiler has about 1,350 tests and the formatter 75.

#figure(
  booktable(
    columns: (auto, 1fr),
    align: (left, left),
    table.header([Layer], [What a test states]),
    table.hline(stroke: 0.5pt),
    [Packages and files],
    [Manifests, paths, resolution of modules and dependencies.],
    [Syntax],
    [A source text and the shape of its tree, or its diagnostic.],
    [Declarations and solver],
    [Signatures, bounds, impl conformance, constants, layouts.],
    [Bodies],
    [Types and diagnostics of expressions, patterns and places.],
    [Lowering],
    [A program is compiled, run under Wasmtime and its result checked.],
    [MIR, optimizer, backend],
    [Inlining, scheduler invariants, modules built by hand from MIR.],
    table.hline(stroke: 0.5pt),
    [Formatter],
    [The text produced for a source, and idempotence.],
  ),
  caption: [The layers of the compiler's tests and of the formatter's.],
) <tbl:impl-tests>

*Diagnostics, not snapshots.* A test of the checker mostly states which diagnostics a program must produce, checked with their severity and not only their code, and a failing assertion prints the source around the diagnostic. A snapshot of a large structure records what the compiler does without saying what it should do, so the parser has only two snapshot tests and the others state the claim.

*Execution tests.* The tests of lowering take a program as text, run the sequence that `wx build` runs, instantiate the module in Wasmtime and call its exports. Wasmtime validates the module on loading, so each of them also checks that the compiler emits valid WebAssembly. A program can be run with and without inlining, so a failure can be assigned to lowering or to the inliner. This is the layer that says what the compiled program does. A second set of tests builds MIR by hand, without the checker, and runs it, which fixes the contract between lowering and the backend.

== State and limits <sec:impl-state>

Not everything described above currently works.

- *The language server and the browser build are unfinished.* Both were written against the checker that was replaced, and `wx lsp` only reports that the server is not connected. They need an entry point of the checker that returns its context, and a rewrite of the server's symbol index and completion over the new tables.
- *Not every checked form is lowered.* Function references (calls through `call_ref`), constants of function or vector type, a slice that is a field and float constant patterns are reported as unsupported.
- *Backend optimization is limited.* It removes common subexpressions and dead values, but lacks complete stack scheduling and control-flow simplification.
