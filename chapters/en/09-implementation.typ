#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote
#import "../../figures/architecture.typ" as arch

= Implementation and Tooling <ch:implementation>

The previous chapters described the language. This chapter describes the program that implements it and why it is built the way it is. Three decisions shape it. First, the compiler is one library, and everything else that works with WX source (the command line, the formatter, the language server, the tests) is a client of it. Second, the type checker is demand-driven and stays alive after it has finished, because later stages keep asking it questions. Third, the compiler passes through several intermediate representations, each of which exists to make one problem small. The chapter ends with the testing methodology and an account of what does not work at the time of writing.

#todo[Every statement about the code was read from the source on 2026-11-06 (branch `tir-refactor`). Re-check the counts and the "not connected" list against the final commit.]

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

Every compilation is rooted at a package, a directory with a `wx.json` manifest that names its entry file and its dependencies. The loader reads the packages into a `CompilationUnit`, always including the standard library, and records a missing or ambiguous `mod` as a diagnostic, so one broken submodule does not hide the errors in the others.

The loader never touches the file system directly. It reads through the `FileSource` trait, which has four implementations: the disk, a map of paths to text (used by the tests and a browser build), the embedded standard library, and an overlay that the language server uses to answer from the buffers an editor has open. One trait is what lets the same loading code run on a file system, in a browser and inside an editor with unsaved changes.

The lexer and parser are written by hand, and the parser produces a syntax tree that keeps the comments, which the formatter needs. The tree holds no semantic identity: declarations are numbered later, by the checker.

All stages report through one diagnostic type, with source spans, labels and notes, and one set of codes ordered by stage. Every client renders the same diagnostics for its own purpose: the command line prints them as text or as JSON, the language server converts them to protocol diagnostics, and the tests assert on them.

== The checker: a live context <sec:impl-check>

The checker is the largest part of the compiler (about two thirds of the compiler's production code), and the one whose structure has the least resemblance to the textbook pipeline of parsing, checking and code generation #fnote("aho2006").

*Signatures on demand.* The checker first scans every item of every file, gives it an identity and claims its name, without typing anything. Then it computes signatures. Declarations refer to one another in any order (a bound names a trait that is written further down, an associated type names another trait's), so a signature is computed when it is first needed and not in source order. Asking for a signature that is already being computed is a cycle, and the checker keeps the stack of queries so that the diagnostic names the whole loop.

*Constructing is not checking.* Building a signature turns the written syntax into types and does not decide whether a bound holds. A place that needs a requirement to hold records it with the declaration, and the requirements are checked once every signature exists. Checking them at the point of construction would force an order on the signatures that the language does not have. A check never rewrites a stored signature: a failure is reported and the type stays as written. Function bodies are checked last, because they are the only part that needs everything else.

*One diagnostic per problem.* Two questions recur throughout the checker: what an associated type or a constant in a type is equal to, and which impl applies to a type. They depend on each other, so one engine, the solver, answers both. A query returns an answer or an error saying why it has none (not final yet, derived from an error someone else reports, out of budget, or a cycle), and it never reports. The construct that wrote the type or the requirement owns the diagnostic. This is what gives one diagnostic per problem: a definition that depends on itself is judged once, and the loop is reported by the first definition in it, whichever one the checker reached first.

*Why the context stays alive.* The checker's context is not frozen when checking ends. This is the second decision, and it follows from what comes next. Lowering a generic function substitutes its type arguments into the checked body and then needs the checker's answers again: the normal form of a type, the layout of an aggregate, the impl a call selects. Rather than copy the tables into a second structure, lowering takes the live context and asks it. The same property is what an editor needs, since a request for the type under the cursor is a query on a finished context. A frozen registry, or a second interner for lowering, would duplicate the question of what a type means. The price is that the context borrows everything it reads, so the caller keeps its inputs on the stack; this is done with plain references, without reference counting or unsafe code.

The entry points show the consequence. `tir::check` runs the checker, drops the context and returns the diagnostics. `tir::build` keeps the context, lowers from it and returns MIR together with the diagnostics.

== From the checked program to bytes <sec:impl-lower>

Three representations follow the checker.

*Lowering and MIR.* The checked program is generic and the module is not, so lowering monomorphizes. It starts from the exports and the globals and lowers a function with its type arguments the first time something calls it, so an instance that nothing reaches is never built. The result, MIR, has the shape of WebAssembly: functions over scalar values, memories with their limits, aggregates with the byte offsets of their layout. A checked form that lowering does not cover yet is reported as unsupported and never dropped, so a missing case is an error and not a wrong program.

MIR is stored as an arena: the expressions of a function are rows in a few columns, referred to by index, and not a tree of boxes. The call graph is then derived from the nodes and inlining splices rows, instead of cloning trees.

*Inlining.* The inliner takes callees marked `#[inline]`, callees no bigger than the call to them, and callees with a single call site, and then drops every function the exports no longer reach. The standard library depends on it: the operators on primitive types are small functions marked `#[inline]` over intrinsics, so `a + b` on integers, which the type system treats as a call of a trait method, ends as one `i32.add` in the module.

*The optimizer.* For each function, a sea-of-nodes graph #fnote("click1995") is built, in which a computation is a node that depends only on its inputs and has no position, and only operations with effects (stores, traps, branches) are ordered. Two identical computations are then one node, so common subexpressions disappear without a separate pass, and a computation nothing uses is never emitted. A scheduler turns the graph back into instructions, keeping a value in a local only when it is used more than once or is a call result, and otherwise leaving it on the stack.

This backend is deliberately simple, and the evaluation shows what that costs: it does not yet schedule for the stack. In particular, the value of an `if`, a `loop` or a block is stored to a local in each branch and read after the construct, instead of being carried by the block's result type, so modules come out larger than necessary. This is a property of the optimizer and not of the language, since the typed result of each construct follows from the types, and a later pass can restore it. For this reason the size study of @sec:wx-comparison also reports the size after Binaryen's `wasm-opt`, which the compiler does not invoke itself.

== The tools around the compiler <sec:impl-tooling>

*Command line.* `wx` is one binary with `build`, `check`, `format` and `lsp`. Every command takes a directory with a `wx.json`; there is no single-file mode, because a package is the unit the language compiles.

*Formatter.* `wx-fmt` prints source from the syntax tree and needs no type information. It builds a document in the style of Wadler's pretty printer #fnote("wadler2003"), a tree of text, line breaks, indentation and groups, and a renderer decides for each group whether it fits in the remaining width. The command line and the language server call the same function with the same configuration, so formatting on save and `wx format` cannot disagree, and a test checks that formatting an already formatted file changes nothing.

*Language server.* The server offers diagnostics, hover, go to definition, references, rename, formatting, signature help, semantic tokens and completion. Its structure answers one problem. Protocol notifications arrive concurrently and the program is rebuilt after every edit; with the state behind a lock, two edits to one file could take the lock in the opposite order from the one the client sent them. The server therefore has one task that owns all the state, and every handler sends it a message over an ordered channel. Edits are applied in order, and an edit is not rebuilt if another edit to the same file is already waiting behind it, since its result would be replaced at once.

*Editors and playground.* An editor extension is a small program in its own repository that finds the `wx` executable and starts `wx lsp`; it contains no compiler. The Visual Studio Code extension (about 560 lines of TypeScript) adds a grammar for highlighting, and the Zed extension adds a tree-sitter grammar. The knowledge of the language stays in one place. A second build of the library, compiled to WebAssembly, takes a map of file names to text and returns diagnostics and the module's bytes; this is the reason for the in-memory file source and for embedding the standard library, and it is how the browser playground compiles WX.

== Testing <sec:impl-testing>

Each stage is tested at its own boundary, with the input it receives and the output it hands on, and the tests of a stage run without the stages after it. @tbl:impl-tests counts them.

#figure(
  booktable(
    columns: (auto, auto, 1fr),
    align: (left, right, left),
    table.header([Layer], [Tests], [What a test states]),
    table.hline(stroke: 0.5pt),
    [Packages and files], [47], [Manifests, paths, resolution of modules and dependencies.],
    [Syntax], [155], [A source text and the shape of its tree, or its diagnostic.],
    [Declarations and solver], [664], [Signatures, bounds, impl conformance, constants, layouts.],
    [Bodies], [196], [Types and diagnostics of expressions, patterns and places.],
    [Lowering], [229], [A program is compiled, run under Wasmtime and its result checked.],
    [MIR, optimizer, backend], [48], [Inlining, scheduler invariants, modules built by hand from MIR.],
    [Test support], [10], [The assertion helpers and the container used by the tests.],
    table.hline(stroke: 0.5pt),
    [Compiler, total], [1349], [],
    [Formatter], [75], [The text produced for a source, and idempotence.],
  ),
  caption: [Tests of the compiler and the formatter, counted on 2026-11-06 with `cargo test -- --list`. Two tests of the parser are ignored.],
) <tbl:impl-tests>

*Assertions over diagnostics.* A test of the checker mostly states which diagnostics a program must produce. A shared helper holds the diagnostics of one stage with the files they point into and offers the few questions a test asks: no errors, this code, not this code, exactly these codes. When an assertion fails it prints what the compiler really produced, with the source around it. A diagnostic is checked with its severity and not only its code, so a warning cannot stand in for an error.

*Few snapshots.* The parser has two snapshot tests, and no other suite has one. A snapshot of a large structure records what the compiler does without saying what it should do. The other tests state the claim: a helper renders an expression as an S-expression, so a test of precedence names the tree it expects (`a + b * c` is `(+ a (* b c))`).

*Execution tests.* The tests of lowering take a program as text, run the sequence that `wx build` runs, instantiate the module in Wasmtime and call its exports. Wasmtime validates the module on loading, so each of them also checks that the compiler emits valid WebAssembly. A program can be run with and without inlining, so a failure can be assigned to lowering or to the inliner. This is the layer that says what the compiled program does.

*Backend tests.* A second set builds MIR by hand, without the checker, and runs it. They fix the contract between lowering and the backend, so the backend can be changed and tested without the type checker in the way.

*Programs.* The programs in `examples` are built and run by a script that compares their output with what each should print. A program that must be rejected is stored as a fragment with the extension `.wx.fail`, which the script appends to a valid program and expects exactly one diagnostic of a given code. Continuous integration does not build the examples, so this script is the only check that the language described in the chapters still works as described.

== State and limits <sec:impl-state>

Not everything described above currently works.

- *The language server and the browser build do not compile.* Both were written against the checker that was replaced, and `wx lsp` prints that the server is not connected to the new checker. What is missing is an entry point of the checker that returns its context, and a rewrite of the server's symbol index and completion over the new tables. The checker was structured with this in mind, but an editor has not exercised it yet. As a consequence, the continuous integration check of the workspace fails on this branch.
- *Not every checked form is lowered.* Function references (calls through `call_ref`), constants of function or vector type, a slice that is a field and float constant patterns are reported as unsupported.
- *The backend is not an optimizer.* It removes common subexpressions and dead values, but it does not schedule for the stack and does not simplify control flow.

#todo[Check against the final commit, and decide whether to restore the language server before submission; if so, rewrite the first item.]
