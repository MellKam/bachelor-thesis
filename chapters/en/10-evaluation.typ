#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote
#import "../../figures/charts.typ" as ch

= Evaluation and Future Work <ch:evaluation>

== Coverage of WebAssembly features <sec:coverage>

WX was put through the same feature probes as the other languages (@sec:exposure), with the same checker and the same acceptance criteria, and built in its own container image. It reaches 10 of the 30 features: imports and exports, memory, floating-point builtins, globals, bulk memory, multi-value, multiple memories and 64-bit memory completely, and two more in part. This is the lowest count of the nine languages, and it is expected: the compiler is a new one, and its language was designed around the features it has. Each missing feature is absent in the compiler, and the language design does not exclude any of them. @fig:wx-coverage lists every feature with the route WX takes to it and, for each gap, what is missing. The reasons differ, and they sort the missing features into four groups.

#figure(
  ch.wx-figure(),
  kind: table,
  caption: [The #ch.n-features WebAssembly features of the study, as WX reaches them, grouped by specification version. A missing feature is absent from the compiler at this stage; the status column says whether it is designed, ready to implement, requires research, has not been considered, or is deferred.],
  placement: auto,
) <fig:wx-coverage>

*Partly reached.* Three features were attempted and fail on one check each. An imported memory takes its limits from the host: the attribute that sets a memory's limits is accepted on a defined memory and rejected on an import, so the import has a minimum of zero and no maximum (feature 2). Static data is placed by the compiler at the start of the memory, and a program can read where it ends but not choose where it begins (feature 6). Of the ten integer operations, `clz`, `ctz`, `popcnt`, `rotl` and `rotr` have no intrinsic (feature 8).

*Instructions that need only an intrinsic.* The sign-extension and saturating conversions (feature 11) and the vector instructions (SIMD, features 15, 16 and 26) are instructions like those the language already exposes. Intrinsics are declared in the standard library by name and bound to an instruction, so each of these is an addition to that list, and the vector type for the second group. The bit-counting operations of feature 8 belong here as well. None has been written yet.

*Features that depend on tables and function references.* Tables (features 3, 4, 18 and 19) are designed but not implemented, and function references (feature 22) are built on them: the type of a function value is already specified to lower to a call through a typed reference, but without tables there is nothing to lower it onto. These five are one piece of work and not five.

*Features that were deferred or need research.* Extended constant expressions (feature 21) need a global whose initial value is computed from an import. An attempt to initialise globals lazily was made and postponed until the design can be settled, and this feature follows from it. Custom sections (feature 7) and passive data segments (feature 13) have not been considered yet: it is not settled which use case a source-level form should serve, and for passive segments the way a program would apply and release one has to be studied. A start function (feature 5) has no recorded design decision. The remaining features, `externref` (17), the garbage-collected types and their casts (23 and 24), exception handling (27 and 28), tail calls (20) and branch hints (30), fit the existing design but are only partly designed. Each needs research into how it would appear in the type system before it is added; the GC types and exception handling are in @sec:future.

The integration criteria (@sec:integration) show the same pattern from the outside. WX produces WASI Preview 1 command modules, but through hand-written imports (the language ships no WASI layer; @ch:hosts builds one as a library), so the route is rated as hand-written. It has no Component Model support, and its compiler has no debug build: the module has no name section, no DWARF and no source map, and a trap shows only a function index. That was tried and set aside for now.


== WX against the other languages <sec:wx-comparison>

The integration criteria and the scoring of @sec:integration were applied to WX unchanged, so its results can be read against the eight languages of that chapter. The figures below add WX to the charts of that chapter, in a highlighted row; the earlier figures were not redrawn.

*Size.* The three programs are the ones of the study: `cat` (WASI Preview 1), `life` and `words`. The measure is the one used for the other languages, the module after Binaryen's `wasm-opt -Oz` (version 133) when that is smaller than the compiler's own output. This matters more for WX than for the others, because the backend does not yet stackify: it holds the parts of aggregates in separate locals, and every intermediate value goes through a local. The raw `cat` is 782 bytes and the raw `words` 692 bytes, about twice the size of the smallest raw modules, and Binaryen removes most of that: after it they are 233 and 307 bytes (@fig:wx-size). The compiler's output is therefore not the size WX modules need to be, and a stack scheduler would narrow the gap. The raw numbers are in the outline of each bar.

#figure(
  ch.size-figure(langs: ch.order + ("wx",), highlight: "wx"),
  kind: "chart",
  caption: [Size of the three programs for the lowest-level build of each language. The `cat` of WX declares the three WASI imports it uses and places its buffers itself; the build through the WASI library of @ch:hosts is 4307 bytes raw and 634 after `wasm-opt`.],
  placement: auto,
) <fig:wx-size>

The language that comes out smallest on `cat` is not a language with a runtime to remove, but one with nothing to link: MoonBit, AssemblyScript and WX call the WASI functions directly, and Zig reaches them through thin bindings, so no library sits behind them. The `cat` of Rust and C links the standard library and is far larger, and so are those of TinyGo, Kotlin and Swift, which carry a runtime. The size score, which is the logarithmic distance from the smallest program of each kind (@sec:integration), is 0.95 for WX, the highest of the nine languages.

*Integration.* @fig:wx-integration shows the five criteria. WX is last, with 0.40: strong on size, weak on what is built around the compiler. A route that the developer writes by hand is weighted by half, and that is what WASI and JavaScript bindings are for WX today: the developer declares the imports and marshals the data. The library of @ch:hosts shows this can be written once in WX itself, but it is not part of the distribution, and the study rates what a developer finds.

This is deliberate. The standard library holds only what the language requires, and host interfaces are packages, so a program can connect to WASI, a browser or an interface that does not exist yet on the same footing. Shipping a WASI Preview 1 layer would be easy, since the library of @ch:hosts is written in WX itself. Preview 1 is a legacy interface, though: current WASI is defined with WIT and the Component Model, and that is where the effort belongs. The planned built-in route is component support, with WASI reached through WIT bindings (@sec:future), and Preview 1 stays an optional package for those who need it. Either would be rated an official tool, as AssemblyScript's WASI shim is, and the WASI score would rise from 0.50 to 0.85; a built-in route would rate 1.00. The same holds for JavaScript bindings. The other two gaps are compiler work: the Component Model needs lowering to the canonical ABI, and the debug build needs name and debug sections. They are marks of a young project, not limits of the language.

#figure(
  ch.integration-figure(langs: ch.order + ("wx",), highlight: "wx"),
  kind: "chart",
  caption: [The integration criteria of @sec:integration with WX added, ordered by the integration score. A dash means the criterion is absent.],
  placement: auto,
) <fig:wx-integration>

*Combined.* @fig:wx-combined puts the exposure and integration scores together with the weights of @sec:integration. WX is ninth, with 0.38, and in the random re-runs of the coefficients its place ranges from seventh to ninth, so Kotlin and Swift are not clearly ahead of it. The score is the sum of the two parts that are weakest for a young language, the number of features reached and the tooling around the compiler, and it says nothing about the part this thesis is about: whether a program can state, in the type system, which memory a pointer belongs to and which entity of the module a declaration is. The study does not measure that, and @sec:coverage lists only what is reached.

#figure(
  ch.combined-figure(langs: ch.order + ("wx",), highlight: "wx"),
  kind: "chart",
  caption: [The combined score of @sec:integration with WX added: 0.6 times the exposure score plus 0.4 times the integration score, with the range of the rank when the coefficients are varied.],
  placement: auto,
) <fig:wx-combined>

== Future work <sec:future>

The language described in this thesis covers the platform's entities, values, calls, instructions and function bodies. The items below are what its examples ran into or left out. Each one is designed to some degree or has a motivating case in the preceding chapters; none of them is finished. They are not in order of priority.

*Sum types.* WX has structs, tuples and enums that are integers, but no type whose value is one of several shapes. The workarounds are visible in the examples: the substring search returns `(Bool, Mem::Size)` in place of an `Option` (@lst:body-search), and a WASI call that produces a value returns a pair of an error number and the value. A sum type would give both a proper form. It also needs a representation on the Wasm stack, which @sec:stack-repr defines as a flat list of values, so a variant must be held as a tag plus the union of its alternatives' values.

*Ranges, slice ranges and iterators.* A slice range `x[a..b]` parses but is reported as unsupported, so code that needs a sub-slice builds it from parts, and the libraries in @ch:hosts do this in one function. Range expressions would fix this, and with an iterator trait they would replace the hand-written `loop` over an index used throughout the examples.

*A `Sized` trait.* The size and alignment of a type are queried today by two intrinsic functions, `size_of` and `align_of`, which take the memory as an argument. A trait that the compiler answers from a type's structure would state the requirement in a bound (`T: Sized`) and give the sizes as constants, as `StackValue` already does for representation. It also lets the checker reject a slice or an array of an unsized element where it is written.

*Generic constants and generic associated types.* A trait can declare an associated type and an associated constant, but the member itself cannot take parameters. A constant cannot depend on a memory's address type (`const N<S: PointerSize>: S`), so a constant length in a generic type has to match the exact `Size`, and an associated type cannot be a family (`type Of<T>`). Both need the same machinery: a frame for the member's own parameters and a value per instance. The compiler already represents a constant that has arguments, but it evaluates only constants without parameters, so both are started and not finished. Generic constants come first.

*Generic traits.* A trait has no parameters of its own beyond `Self`, and a type has at most one implementation of a trait. This keeps method lookup and operator dispatch unambiguous, and it is a deliberate rule, but it rules out a trait such as a conversion from one type to another. Whether to add trait parameters, and how to keep the rule for the cases that rely on it, is an open question and not a decision.

*Package parameters.* A package cannot take a memory as a parameter, so a library that imports host functions has to declare the memory itself (@sec:hosts-limits). Making a package a template over a memory, instantiated by the program that uses it, would let such a library be an ordinary dependency.

*Effect tracking.* The design in the repository is a local, opt-in system: every function is impure unless it is annotated, and an annotation is a bound on the effects a function may perform, checked without inferring through callees. It would let a signature say that a function does not touch memory, or only touches one. The WebAssembly proposal for typed continuations and effect handlers (WasmFX) is the platform's counterpart, and connecting the two is open work.

*Ownership and borrowing.* Pointers carry a sigil, `*` for exclusive and `&` for shared, but the checker enforces no discipline on them. A view can outlive the memory it points into: the arena in @sec:wasi-library hands out cells that a later call reuses, and nothing prevents a program from keeping one. A borrow checker is designed but not implemented, and it would turn those conventions into errors.

*Garbage-collected types.* WX exposes linear memory and the reference types that exist as values. The GC proposal adds structs and arrays that the host manages, referred to through typed references instead of addresses #fnote("wasm-proposals"). They would be a second kind of memory-like entity: a reference has no address, so the pointer types of this thesis do not describe it, and the type system would need a form for it.

*The Component Model and WIT.* The WASI library of @ch:hosts targets Preview 1, which needs only core WebAssembly. Later WASI versions and most multi-language integration are defined with the Component Model #fnote("wasm-component-model"), whose interfaces are written in WIT #fnote("wasm-wit"). Supporting it means generating the declarations of imports and exports from an interface description, and lowering WX's values to the canonical representation of its types. WX's explicit memories and boundary signatures are a good basis, because the canonical ABI is stated in terms of a memory and of numbers.
