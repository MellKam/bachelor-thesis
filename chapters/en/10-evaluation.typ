#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote
#import "../../figures/charts.typ" as ch

= Evaluation and Future Work <ch:evaluation>

== Coverage of WebAssembly features <sec:coverage>

WX was tested with the same feature probes, checker and acceptance criteria as the other languages (@sec:exposure). It reaches 10 of the 30 feature groups: seven fully and three partly. This ties with TinyGo for the lowest reached count. The results establish coverage of the implemented subset; support for the remaining features requires further implementation or design work. @fig:wx-coverage lists the route to each feature and the status of each gap.

#figure(
  ch.wx-figure(),
  kind: table,
  caption: [The #ch.n-features WebAssembly features of the study, as WX reaches them, grouped by specification version. A missing feature is absent from the compiler at this stage; the status column says whether it is designed, ready to implement, requires research, has not been considered, or is deferred.],
  placement: auto,
) <fig:wx-coverage>

*Partly reached.* Three features were attempted and fail on one check each: an imported memory takes its limits from the host, so the limits attribute is rejected on an import (feature 2); static data is placed by the compiler at the start of the memory, and a program cannot choose where it begins (feature 6); and `clz`, `ctz`, `popcnt`, `rotl` and `rotr` have no intrinsic (feature 8).

*Instructions that need only an intrinsic.* The sign-extension and saturating conversions (feature 11) and the vector instructions (features 15, 16 and 26) are like the instructions the language already exposes: each is a declaration in the standard library bound to an instruction, plus a vector type for the second group. None has been written yet.

*Features that depend on tables and function references.* Tables (features 3, 4, 18 and 19) are designed but not implemented, and function references (feature 22) are built on them: the type of a function value is already specified to lower to a call through a typed reference, but without tables there is nothing to lower it onto. These five are one piece of work and not five.

*Features that were deferred or need research.* Extended constant expressions (feature 21) follow from an attempt at lazily initialised globals that was postponed. Custom sections (feature 7), passive data segments (feature 13) and a start function (feature 5) have not been designed: it is not settled which use case a source-level form should serve. The rest (`externref`, the garbage-collected types and casts, exception handling, tail calls and branch hints: features 17, 20, 23, 24, 27, 28 and 30) fit the existing design but each needs research into how it would appear in the type system; GC types and exception handling are in @sec:future.

== WX against the other languages <sec:wx-comparison>

The integration criteria and the scoring of @sec:integration were applied to WX unchanged, so its results can be read against the eight languages of that chapter. The figures below add WX to the charts of that chapter, in a highlighted row; the earlier figures were not redrawn.

*Size.* The three programs are the ones of the study: `cat` (WASI Preview 1), `life` and `words`. The measure is the one used for the other languages, the module after Binaryen's `wasm-opt -Oz` when that is smaller than the compiler's own output. This matters more for WX than for the others, because the backend does not yet stackify: it holds the parts of aggregates in separate locals, and every intermediate value goes through a local. The raw `cat` and `words` are about twice the size of the smallest raw modules, and Binaryen removes most of that (@fig:wx-size). The compiler's output is therefore not the size WX modules need to be, and a stack scheduler would narrow the gap.

#figure(
  image("../../figures/build/size-wx-en.png", width: 100%, alt: "Bar chart of the size of the programs cat, life and words for nine languages, on a logarithmic scale from 100 B to 10 MB. WX: 233 B, 544 B and 307 B; the smallest modules, AssemblyScript, are 181 B, 408 B and 324 B, and the largest, Swift, are 3.6 MB, 11.2 kB and 10.7 kB."),
  kind: "chart",
  caption: [Size of the three programs for the lowest-level build of each language. The `cat` of WX declares the three WASI imports it uses and places its buffers itself; the build through the WASI library of @ch:hosts is 4307 bytes raw and 634 after `wasm-opt`.],
  placement: auto,
) <fig:wx-size>

The smallest `cat` modules are probably small because nothing is linked in behind them: MoonBit, AssemblyScript and WX call the WASI functions directly, and Zig reaches them through thin bindings. The `cat` of Rust and C links the standard library and is far larger, and so are those of TinyGo, Kotlin and Swift, which carry a runtime. The size score, which is the logarithmic distance from the smallest program of each kind (@sec:integration), is 0.95 for WX, the highest of the nine languages. The comparison measures the size of specific programs. The shared test only checks that `cat` copies text and empty input and exits with code 0; it does not require the same error handling or binary input.

*Integration.* @fig:wx-integration shows the five criteria. WX is last, with 0.40: strong on size, weak on what is built around the compiler. A route that requires hand-written code scores 0.50 instead of the 1.00 of a route built into the toolchain, and that is what WASI and JavaScript bindings are for WX today: the developer declares the imports and marshals the data. The library of @ch:hosts shows this can be written once in WX itself, but it is not part of the distribution, and the study rates what a developer finds.

The hand-written route is deliberate: the standard library holds only what the language requires, and host interfaces are packages, so a program can connect to WASI, a browser or an interface that does not exist yet on the same footing. The other two gaps are compiler work. The Component Model needs lowering to the canonical ABI, and there is no debug build, so a module has no name section, DWARF or source map, and a trap shows only a function index.

#figure(
  ch.integration-figure(langs: ch.order + ("wx",), highlight: "wx"),
  kind: "chart",
  caption: [The integration criteria of @sec:integration with WX added, ordered by the integration score. A dash means the criterion is absent.],
  placement: auto,
) <fig:wx-integration>

In summary, WX reaches 10 of the 30 features, all of them as source constructs or annotations and none through build configuration or inline assembly. That is more features as constructs than Swift (9), Zig (8) or TinyGo (5) offer, and one fewer than Rust (11), which reaches 24 in total but most of them through configuration or assembly. WX has the highest size score of the nine languages. Its integration score is the lowest: its WASI and JavaScript routes are hand-written, and it has no Component Model support or debug build.

== Future work <sec:future>

The language described in this thesis covers the platform's entities, values, calls, instructions and function bodies. The items below are what its examples ran into or left out. Each one is designed to some degree or has a motivating case in the preceding chapters; none of them is finished. They are not in order of priority.

*Sum types.* WX has structs, tuples and enums that are integers, but no type whose value is one of several shapes. The workarounds are visible in the examples: the substring search returns `(Bool, Mem::Size)` in place of an `Option` (@lst:body-search), and a WASI call that produces a value returns a pair of an error number and the value. A sum type would give both a proper form. It also needs a representation on the Wasm stack, which @sec:stack-repr defines as a flat list of values, so a variant must be held as a tag plus the union of its alternatives' values.

*Smaller language extensions.* A slice range `x[a..b]` parses but is reported as unsupported, so code builds a sub-slice from parts (@ch:hosts), and iterators would replace the hand-written index loops of the examples. A `Sized` trait would state the size and alignment of a type in a bound instead of two intrinsics. Generic constants (`const N<S: PointerSize>: S`) are started and not finished, and generic traits are a deliberate restriction whose relaxation is an open question.

*Package parameters.* A package cannot take a memory as a parameter, so a library that imports host functions has to declare the memory itself (@sec:hosts-limits). Making a package a template over a memory, instantiated by the program that uses it, would let such a library be an ordinary dependency.

*Effect tracking.* The design in the repository is a local, opt-in system: every function is impure unless it is annotated, and an annotation is a bound on the effects a function may perform, checked without inferring through callees. It would let a signature say that a function does not touch memory, or only touches one. The WebAssembly proposal for typed continuations and effect handlers (WasmFX) is the platform's counterpart, and connecting the two is open work.

*Ownership of resources.* Pointers carry a sigil, `*` for mutable and `&` for read-only, meant to become an exclusive pointer and a shared reference, but the checker enforces no discipline on them beyond the right to write. A view can outlive the memory it points into: the arena in @sec:wasi-library hands out cells that a later call reuses, and nothing prevents a program from keeping one. Turning those conventions into errors would need some form of linear types to manage such resources, which the language does not have yet.

*Garbage-collected types.* WX exposes linear memory and the reference types that exist as values. The GC proposal adds structs and arrays that the host manages, referred to through typed references instead of addresses #fnote("wasm-proposals"). They would be a second kind of memory-like entity: a reference has no address, so the pointer types of this thesis do not describe it, and the type system would need a form for it.

*Language server and browser build.* Both exist but target the previous checker (@sec:impl-state). Reconnecting them needs an entry point of the checker that returns its context, and a rewrite of the symbol index and completion over the new tables.

*The Component Model and WIT.* The WASI library of @ch:hosts targets Preview 1, which needs only core WebAssembly. Later WASI versions and most multi-language integration are defined with the Component Model #fnote("wasm-component-model"), whose interfaces are written in WIT #fnote("wasm-wit"). Supporting it means generating the declarations of imports and exports from an interface description, and lowering WX's values to the canonical representation of its types. WX's explicit memories and boundary signatures are a good basis, because the canonical ABI is stated in terms of a memory and of numbers.
