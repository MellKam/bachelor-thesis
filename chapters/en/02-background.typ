#import "../../template.typ": todo, booktable, muted
#import "../../figures/charts.typ" as ch

// Where the full study lives. Pin this to a tagged commit before submission.
#let study-url = "https://github.com/MellKam/bachelor-thesis/tree/main/wasm-exposure-study"

= Background and Related Work <ch:background>

// Chapter plan (see also chapter-2-test-matrix.md):
//   2.1 The structure of a WebAssembly module          written
//   2.2 Comparing languages                             first draft (shared design, evidence, scores)
//   2.3 Exposure: tests, rating, results                first draft, charts native
//   2.4 Integration: tests, rating, results             first draft, charts native
//   2.5 Combined ranking                                first draft
//   2.6 Synthesis and design questions                  first draft

== The structure of a WebAssembly module <sec:module-structure>

A WebAssembly program is delivered as a module: a self-contained unit that a host, such as a browser or a standalone runtime, loads and instantiates. A module consists of several kinds of entity. The main ones are:

- *Functions* are units of code, each with a typed signature.
- *Memories* are growable arrays of bytes.
- *Globals* hold a single value of a declared type and have a specified mutability.
- *Tables* hold references and are used mainly for indirect calls.
- *Tags* are nominal identifiers associated with type signatures, currently used for exceptions in WebAssembly.

A module can define these entities itself or import them from the host, and it can choose which of its entities to export @wasm-spec-modules.

This thesis uses WAT, the text format of WebAssembly, to illustrate modules. Parentheses group the different parts of a module, and names beginning with `$` identify entities. Instructions can be nested for readability. For example, `(call $log (i32.const 42))` passes the constant `42` to `$log`. Although written in nested form, the instructions execute in sequence: the constant is evaluated before the function is called.

Consider the small module in @lst:wat-example.

#figure(
  ```wat
  (module
    (import "host" "log" (func $log (param i32)))
    (func $run
      (call $log (i32.const 42)))
    (export "run" (func $run)))
  ```,
  caption: [A minimal WebAssembly module in the text format.],
) <lst:wat-example>

+ Import the function `"log"` from the `"host"` namespace and give it the internal name `$log`. It takes one `i32` parameter.
+ Define the function `$run`, which calls `$log` with the constant `42`.
+ Export `$run` under the name `"run"` so the host can access it.

=== The sandbox <sec:sandbox>

This module cannot log anything by itself. The host must provide the imported function `host.log` when it instantiates the module. This illustrates a central aspect of WebAssembly's sandboxing model: a module can interact with its environment only through capabilities made available to it, such as imported functions and memories @wasm-spec-intro.

Three properties help enforce this boundary:

+ *Memory access is bounded.* A module can access only the memories available to it, whether defined internally or imported. Every memory access is bounds-checked, and an access outside the memory's current bounds traps.
+ *Structured control flow.* Branches follow WebAssembly's structured control-flow rules, and indirect calls are checked against the expected function type. These rules constrain execution, although they do not prevent bugs within the module.
+ *External access goes through imports.* Files, network access, and the system clock are not inherently available to a module. The host must expose such capabilities through imported functions or other interfaces.

The sandbox has important limits. It protects the host environment from direct, unauthorized access by the module, but it does not protect the module from its own bugs: linear memory is an untyped byte array, so a program can corrupt its own data while remaining within its memory bounds. Furthermore, an imported function can grant substantial authority. WASI, for example, defines interfaces for filesystem access and other system services, but the capabilities available to a module depend on what the host actually provides. WASI is not part of the core WebAssembly specification.

=== Extensions to the core <sec:extensions>

The WebAssembly core specification defines the platform's basic instruction set and execution model. Additional features have been incorporated into the specification over time, while other proposals continue to evolve @wasm-proposals. Some capabilities can be approximated using existing instructions and runtime support, but such workarounds may add complexity, reduce performance, or provide different safety guarantees. Others require new platform support.

Several extensions are particularly relevant to the language design explored in this thesis:

- *Multi-memory* allows a module to use multiple linear memories. These memories can serve different purposes, such as separating private data from memory shared with the host or keeping independently managed data in distinct address spaces. Multiple memories can also help when composing components that expect different memories.
- *Reference types* allow a module to hold and pass references to objects it cannot inspect directly. For example, a host can provide an opaque reference to an external object, such as a DOM node, through an `externref`. The module can pass the reference around or store it in a suitable table without representing it as a manually managed integer handle.
- *Multi-value* allows functions and blocks to produce multiple results. This can avoid the need to pass an output pointer when a function needs to return several values.
- *SIMD* introduces the `v128` value type and vector instructions that can perform operations on multiple numeric lanes in parallel.
- *Exception handling* allows a module to throw and catch typed exceptions. Tags identify exception types, allowing handlers to distinguish between different kinds of exceptions. This is separate from WebAssembly traps, which represent execution failures and are not ordinary catchable exceptions.

These features expand the set of capabilities available to WebAssembly programs, but their presence in the platform does not guarantee that a particular source language exposes them directly. A language may provide native constructs for a feature, require library support or compiler-specific mechanisms, or not support it at all.

These entities and instructions form the surface of the platform: the concepts a developer may want to express in a program. The rest of this chapter examines how different programming languages expose this surface, and how their design choices affect the way developers work with WebAssembly.

== Comparing languages <sec:method>

This section captures where the WebAssembly ecosystem stands today, as seen from eight languages. It asks two questions of each. The first is about *exposure*: for each feature WebAssembly provides, how much of it can a developer name, configure and control from source code? The second is about *integration*: what does it cost to use the module that comes out, that is, to run it outside a browser, package it as a component, call it from JavaScript, debug it and keep it small? Neither question concerns performance or code quality, and neither ranks languages by merit: several of the languages compared deliberately hide the platform. The two axes are tested and reported separately (@sec:exposure, @sec:integration) and combined only at the end (@sec:combined).

*Languages.* Eight language columns were studied (@tbl:languages). C and C++ share a column because they use one toolchain. MoonBit has two backends, `wasm` and `wasm-gc`, that cannot be combined in one module; each probe is run on both and a feature that only the other backend offers is counted as an obstacle. The set was chosen for current use as a WebAssembly target and for variety in design intent. It is not complete: Emscripten, Go's standard compiler and Dart are known omissions.

#figure(
  booktable(
    columns: (auto, 1fr, auto, auto),
    align: (left, left, left, left),
    table.header([Language], [Version], [Memory model], [Route]),
    table.hline(stroke: 0.5pt),
    [Rust], [1.99.0], [linear], [LLVM],
    [Zig], [0.16.0], [linear], [LLVM],
    [C/C++], [clang 23.1.0 (wasi-sdk 34.0)], [linear], [LLVM],
    [Swift], [6.4.0 (Embedded Swift)], [linear], [LLVM],
    [MoonBit], [`moon` 0.1.20260920, `moonc` v0.10.14], [linear / Wasm GC], [own backend],
    [AssemblyScript], [0.28.20], [linear + runtime GC], [Binaryen],
    [TinyGo], [0.42.0 (Go 1.27.1)], [linear + runtime GC], [LLVM],
    [Kotlin], [2.4.21 (Kotlin/Wasm)], [Wasm GC], [own backend],
  ),
  caption: [The languages compared, in the order used by all figures: grouped by memory model.],
) <tbl:languages>

The route column matters for reading the results. Rust, Zig, C/C++, Swift and TinyGo all compile through LLVM and link with `wasm-ld`, so they share whatever that path can and cannot express. AssemblyScript emits WebAssembly directly and uses Binaryen as its optimiser. MoonBit and Kotlin have their own backends, which is how they can offer features, such as Wasm GC, that LLVM does not. #todo[Verify the `wasm-ld` and Binaryen claims against primary sources.]

*How it was verified.* For every test, we write a small program with the language's official documentation and idioms and build it with its standard toolchain, pinned in a container. A checker inspects the compiled `.wasm`, by decoding it, instantiating it in V8 or running it under Wasmtime or Node; our own impression never decides a result. Everything below is a snapshot of pinned versions taken between 2026-10-02 and 2026-10-09. It is indicative, not exact: a later release, a more idiomatic program or a cleverer approach could move individual cells. The full study, with every probe, the checker and the per-cell evidence, is in the project repository @wx-study. #todo[pin commit hash or tag]

== Exposure <sec:exposure>

=== What is tested <sec:exposure-tests>

Thirty features from the released versions of the specification (1.0, 2.0 and 3.0) were probed. A feature is either a piece of module structure (a memory, a global, a tag) or a family of instructions probed as one unit, such as SIMD. For every feature and language, a small program tries to make the feature appear in the compiled module. Each pair receives one result, which says where the feature lives relative to the language (@tbl:vocabulary); a result reached with a caveat carries a flag, for example *partial* when only part of the feature can be controlled.

#figure(
  booktable(
    columns: (auto, auto, auto, 1fr),
    align: (left, center, center, left),
    table.header([Result], [In source], [Checked by compiler], [Meaning]),
    table.hline(stroke: 0.5pt),
    [Native], [yes], [yes], [a language construct, or a typed library or intrinsic function; the compiler may choose the encoding],
    [Annotation], [yes], [yes], [an attribute on an ordinary construct],
    [Config], [no], [no], [a build flag, configuration file or linker argument],
    [Inline assembly], [yes], [no], [assembly or Wasm text written by hand],
    [Absent], [n/a], [n/a], [no way found; _confirmed_ if documentation or compiler rejects it, _not found_ otherwise],
  ),
  caption: [The vocabulary used to classify every cell of the comparison.],
) <tbl:vocabulary>

=== How it is rated <sec:exposure-rating>

The counts of results are the evidence. A single score between 0 and 1 per language summarises them: each feature counts fully, partially or not at all, is discounted for every obstacle on the way (a build option, hand-written assembly, an experimental or nightly compiler, a runtime shipped in every module, a restricted host, or a different backend), and counts more if it belongs to the module core that every program uses. The discounts and weights are our own choice and are listed in the repository. They are meant to order the languages roughly, not to measure them to the second decimal.

=== Results <sec:results>

#todo[First draft, written from the generated data. All counts below are computed from `rating.json`; the commentary needs a review pass against the per-cell evidence before it is final.]

@fig:matrix gives the complete result. Of the #ch.n-pairs language–feature pairs, #ch.n-reached are reached in some way and #ch.n-absent are absent. Only #ch.n-construct are reached as a language construct or annotation; #ch.n-config need a build option outside the source and #ch.n-asm are possible only as hand-written assembly or Wasm text.

#figure(
  ch.matrix-figure(),
  kind: image,
  supplement: [Figure],
  caption: [How each language reaches each of the #ch.n-features WebAssembly features, grouped by memory model and by specification version. The cell shows the best route found.],
  placement: auto,
) <fig:matrix>

*Coverage is uneven across features.* Only #ch.reached-by-all.len() features are reached by every language (#ch.list-of(ch.reached-by-all)), and only #ch.construct-in-all.len() of those, #ch.list-of(ch.construct-in-all), are a language construct or annotation in all #ch.n-languages. #ch.reached-by-none.len() features are reached by none: #ch.list-of(ch.reached-by-none). For #ch.construct-in-none.len() of the #ch.n-features features no language offers a construct or annotation at all; the best any of them manages is a build option or hand-written assembly. These include the memory's limits and names, the placement of data, multi-value results and 64-bit memory, that is, the parts of the module that describe its shape rather than its computation.

*No language covers the platform.* @fig:reach counts how each language reaches the thirty features. Even the broadest, which reaches #ch.broadest.reached of #ch.n-features, reaches #(ch.broadest.reached - ch.broadest.counts.reachedVia.language) of them only through configuration or assembly, and the narrowest reaches #ch.narrowest.reached.

#figure(
  ch.reach-figure(),
  kind: image,
  supplement: [Figure],
  caption: [Number of the #ch.n-features features each language reaches as a language construct or annotation, through build configuration, as inline assembly, or not at all.],
) <fig:reach>

*The profiles are complementary, not nested.* @fig:versions splits the same result by specification version. The languages built on linear memory reach most of versions 1.0 and 2.0 but fewer of the 3.0 features, while Kotlin's profile is the reverse: it reaches the GC and exception features of 3.0 but only 4 of the 10 core features. The two GC features are reached only by Kotlin and by MoonBit's `wasm-gc` backend; passive data segments and 64-bit memory are reached only by languages on linear memory. No language reaches both groups, and MoonBit, which has both, offers them on separate backends that cannot be combined in one module. This is the pattern @sec:problem describes: using both usually means combining languages.

#figure(
  ch.version-figure(),
  kind: image,
  supplement: [Figure],
  caption: [Features reached, out of those probed, per specification version.],
) <fig:versions>

*The exposure score.* @fig:exposure orders the languages. #ch.lang-name(ch.by-exposure.first()) is first at #ch.fmt2(ch.lang.at(ch.by-exposure.first()).score) and #ch.lang-name(ch.by-exposure.last()) last at #ch.fmt2(ch.lang.at(ch.by-exposure.last()).score). The ordering is firm between two groups, C/C++, Rust, Zig and AssemblyScript above Swift, MoonBit, TinyGo and Kotlin, and loose within them, which is why the figure gives a rank range. The score follows how many features a language reaches more than how cleanly it reaches them.

#figure(
  ch.exposure-figure(),
  kind: image,
  supplement: [Figure],
  caption: [Exposure score (0 to 1) per language, ordered, with the range of its rank when the scoring coefficients are varied at random 2000 times.],
) <fig:exposure>

== Integration <sec:integration>

=== What is tested <sec:integration-tests>

Exposure says how much of the platform a language lets the developer reach. Integration asks what it costs to use the module that comes out. A language can reach little of the platform and still produce modules that are easy to run, call and debug, and the reverse is also possible. Five criteria are scored and a sixth is only reported (@tbl:criteria). They use three small programs, each with one host script shared by all languages: `life` (pure computation on linear memory), `cat` (a WASI command that copies standard input to standard output) and `words` (a string in, a record out).

#figure(
  booktable(
    columns: (auto, 1fr, auto),
    align: (left, left, left),
    table.header([Criterion], [Test], [Scored by]),
    table.hline(stroke: 0.5pt),
    [I1 WASI], [`cat` is built for the WASI target and run under Wasmtime], [route],
    [I2 Component Model], [`words` is built as a component with a typed interface and called under Wasmtime; only direct support counts, not hand-written glue], [route],
    [I3 JS bindings], [`words` is called from Node with a string and returns an object, through the glue the language's tooling generates], [route],
    [I4 Debuggability], [a debug build of `life` is checked for a name section, DWARF or a source map, and a trap whose stack names the source function], [full or partial],
    [I5 Size], [all three programs are built as a smallest and as a default build and measured after `wasm-opt -Oz`], [bytes],
    [I6 Toolchain cost], [installed size of the toolchain, cold build time, and extra tools needed], [reported only],
  ),
  caption: [The integration criteria.],
) <tbl:criteria>

=== How it is rated <sec:integration-rating>

Criteria I1 to I3 are scored by *route*, from best to worst: built into the language's own toolchain, an official extra tool (from the language's project or the Bytecode Alliance), a community tool, or glue the developer writes by hand. A route without direct support scores 0. Size is scored on a log scale, so that one very large runtime does not flatten the rest: a build 1000 times the smallest scores 0. The integration score is the weighted mean of I1 to I5, with the weights given in @fig:integration. As with exposure, these coefficients are our choice and the score is only a summary.

=== Results <sec:integration-results>

#todo[First draft, written from the generated data; the commentary needs a review pass against the per-cell evidence.]

@fig:integration gives the score of every language on each criterion. #ch.lang-name(ch.by-integration.first()) is the easiest module to use (#ch.fmt2(ch.integ.at(ch.by-integration.first()).integration)) and #ch.lang-name(ch.by-integration.last()) the hardest (#ch.fmt2(ch.integ.at(ch.by-integration.last()).integration)).

#figure(
  ch.integration-figure(),
  kind: image,
  supplement: [Figure],
  caption: [Score of each language on the five scored integration criteria (0 to 1; – means no direct support) and the integration score, their weighted mean. The weight of each criterion is given under its name.],
  placement: auto,
) <fig:integration>

*Running outside a browser is nearly solved.* All eight languages run `cat` as a WASI command, six with their ordinary toolchain. *The Component Model separates them.* Only #ch.order.filter(l => ch.integ.at(l).per.I2 > 0).len() have a direct route, all through an official tool and none through the compiler itself; Zig, AssemblyScript, Kotlin and Swift have none. *JavaScript bindings* come from the language's own tooling in AssemblyScript and TinyGo, from an official tool in Rust, C/C++ and MoonBit, from a community tool in Swift, and by hand in Zig. Debug builds are almost uniformly fine, with MoonBit partial.

*Size separates the languages with a bundled runtime.* On `life`, the smallest builds range from 408 bytes for AssemblyScript to 61 KB for Kotlin, and Swift's default build is 3.4 MB. Swift and Kotlin therefore score lowest on I5 (#ch.fmt2(ch.integ.swift.per.I5) and #ch.fmt2(ch.integ.kotlin.per.I5)). Toolchain cost (I6) is not scored, but it shows the same split: Swift's toolchain is #ch.fmt2(ch.i6.swift.footprintMB / 1000) GB, the largest, and Kotlin's cold build of `words` the slowest at #calc.round(ch.i6.kotlin.buildSeconds, digits: 1) s.

== Combined ranking <sec:combined>

#todo[First draft, written from the generated data; the commentary needs a review pass.]

The two scores are combined as #ch.w-exposure × exposure + #ch.w-integration × integration, so that exposure, the subject of this thesis, counts a little more. The split is our choice. @fig:combined shows the result, with each bar divided into the part contributed by each axis.

#figure(
  ch.combined-figure(),
  kind: image,
  supplement: [Figure],
  caption: [Combined score per language (#ch.w-exposure × exposure + #ch.w-integration × integration), ordered, with the range of its rank when the coefficients are varied at random 2000 times. A full-length bar would be 1.0.],
) <fig:combined>

*The top is firm and the middle is a cluster.* #ch.lang-name(ch.by-combined.at(0)) and #ch.lang-name(ch.by-combined.at(1)) are first and second however the coefficients are varied, at #ch.fmt2(ch.integ.at(ch.by-combined.at(0)).combined) and #ch.fmt2(ch.integ.at(ch.by-combined.at(1)).combined), because each is ahead on both axes. #ch.lang-name(ch.by-combined.at(2)), #ch.lang-name(ch.by-combined.at(3)), #ch.lang-name(ch.by-combined.at(4)) and #ch.lang-name(ch.by-combined.at(5)) lie within #ch.fmt2(ch.integ.at(ch.by-combined.at(2)).combined - ch.integ.at(ch.by-combined.at(5)).combined) of each other and should be read as a group, not a ladder.

*The axes pull in different directions.* TinyGo moves from place #ch.place-of(ch.by-exposure, "tinygo") to place #ch.place-of(ch.by-combined, "tinygo"): it covers little of the platform but its modules are among the best integrated. Swift moves from place #ch.place-of(ch.by-exposure, "swift") to place #ch.place-of(ch.by-combined, "swift"), with no component route and the largest modules.

*How to read these numbers.* They are a snapshot of our probes against pinned toolchains, and we are not equally expert in every language. The probe set samples the specification rather than covering it, the integration programs are small, and a cell marked _not found_ means no way was found, which is weaker than impossible. Some routes are counted conservatively: a hand-built component is not support for components. The study does not test whether a language checks the host boundary for safety. The scores summarise the counts and are not a verdict on any language.

== Synthesis and design questions <sec:synthesis>

The core of WebAssembly is well covered. #ch.cap-first(ch.list-of(ch.construct-in-all)) are a language construct in all #ch.n-languages languages, and #ch.order.filter(l => ch.lang.at(l).bySpecVersion.at("1.0").reached >= 7).len() of them reach at least 7 of the 10 features of specification 1.0. The gaps are in the parts that shape the module and in the newer extensions. They are not defects: a language that hides the platform may be the right choice for its audience. But they show what a developer working in any of these languages cannot ask for, and each one is a question for a language built around the platform's own model.

@fig:entities isolates the #ch.entity-features.len() features that correspond to WebAssembly's module entities: the memory section, multiple memories, globals, tables (indirect calls, import and export, and multiple tables) and exception tags. No language offers a construct for more than #ch.max-entity-constructs of them.

#figure(
  ch.entity-figure(),
  kind: image,
  supplement: [Figure],
  caption: [How each language reaches the features that correspond to WebAssembly's module entities. A subset of @fig:matrix.],
) <fig:entities>

Some of these gaps belong to the toolchain more than to the language. Where the five languages that compile through LLVM and `wasm-ld` all lack a construct that a language with its own backend offers, the toolchain is the more likely cause: this holds for #ch.list-of(ch.llvm-gap). Where no language offers a construct at all (#ch.list-of(ch.construct-in-none)), the cause is more likely the platform's youth, or an interface, such as linker flags, that every toolchain exposes in the same way. A language that controls its own compiler is not bound by either, which is why the questions below are about the language and not only about one toolchain. #todo[Verify that the shared LLVM gaps (single memory, no start section, memory and data placement) come from `wasm-ld`, with primary sources.]

The gaps lead to five questions, which the design in Chapter 3 sets out to answer.

+ *Declared entities.* Memory limits and names are set by a build option in #ch.n-by-route("02", "config") of the #ch.n-languages languages and cannot be reached at all in Kotlin. Globals are a language construct only in #ch.languages-where("10", ch.is-construct).map(ch.lang-name).join(", ", last: " and "). Tables appear only implicitly, as the target of indirect calls (a construct in #ch.n-by-route("03", "construct") languages): importing or exporting one is a build option in #ch.n-by-route("04", "config") languages, and a second table needs inline assembly in #ch.n-by-route("18", "asm") and is absent in the rest. Tags are a construct only in #ch.languages-where("27", ch.is-construct).map(ch.lang-name).join(", ", last: " and "). Imports and exports are a construct in every language, which shows that a module entity can be declared in the source. Can memories, globals and a module's imports and exports all be typed constructs, instead of build options or assembly? Tables and tags raise the same question, but the implementation does not cover them (@sec:scope).
+ *Several memories.* Multiple memories are reached by no language. Can a program use more than one memory, with each memory part of the type system and not an accident of the toolchain?
+ *No imposed model.* No language reaches both the linear-memory features and the GC features, and MoonBit, which has both, offers them on backends that cannot be combined in one module (@fig:versions). Even the languages built for WebAssembly reach #ch.lang.assemblyscript.reached (AssemblyScript) and #ch.lang.moonbit.reached (MoonBit) of the #ch.n-features features, fewer than Rust, Zig and C/C++. Can a language avoid a mandatory runtime or memory-management model, so that capabilities are adopted as a program needs them and the two kinds could eventually meet in one module?
+ *Checked access to instructions.* Where a language offers a route to a feature through inline assembly (#ch.n-asm-routes cells), its compiler checks none of them (#ch.n-asm-checked checked). Can a language give typed access to raw platform instructions, so that the compiler checks them?
+ *Declared host boundary.* Only #ch.n-i-route("builtin") of #ch.n-i-cells cells for WASI, components and JavaScript bindings work with the language's own toolchain alone. #ch.n-i-tool need an extra tool, #ch.n-i-route("hand-written") hand-written glue, and #ch.n-i-absent have no support. Can the interface to the host be written in the source, so that less glue is needed?
