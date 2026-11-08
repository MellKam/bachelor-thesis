#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote
#import "../../figures/charts.typ" as ch

// Where the full study lives. Pin this to a tagged commit before submission.
#let study-url = "https://github.com/MellKam/bachelor-thesis/tree/main/wasm-exposure-study"

= Background and Related Work <ch:background>

This chapter introduces the WebAssembly concepts needed to understand WX, then compares how existing languages expose them. The comparison examines access to platform features and integration with hosts, and ends with questions that guide WX's design.

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

A module can define these entities itself or import them from the host, and it can choose which of its entities to export #fnote("wasm-spec-modules").

This thesis uses WAT, the text format of WebAssembly, to illustrate modules. Parentheses group the parts of a module, and names beginning with `$` identify entities. In @lst:wat-example, the nested instructions pass the constant `42` to the imported function `$log`.

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

This module cannot log anything by itself. The host must provide the imported function `host.log` when it instantiates the module. This illustrates a central aspect of WebAssembly's sandboxing model: a module can interact with its environment only through capabilities made available to it, such as imported functions and memories #fnote("wasm-spec-intro").

Three properties help enforce this boundary:

+ *Memory access is bounded.* A module can access only the memories available to it, whether defined internally or imported. Every memory access is bounds-checked, and an access outside the memory's current bounds traps.
+ *Structured control flow.* Branches follow WebAssembly's structured control-flow rules, and indirect calls are checked against the expected function type. These rules constrain execution, although they do not prevent bugs within the module.
+ *External access goes through imports.* Files, network access, and the system clock are not inherently available to a module. The host must expose such capabilities through imported functions or other interfaces.

The sandbox does not protect a module from its own bugs: a program can corrupt data within its linear memory while staying inside its bounds. Imported functions can also grant substantial authority. WASI defines interfaces for filesystem access and other system services, but the host chooses which capabilities to provide. WASI is separate from the core WebAssembly specification.

=== Extensions to the core <sec:extensions>

WebAssembly's instruction set and execution model have expanded through extensions incorporated into the core specification, while other proposals continue to evolve #fnote("wasm-proposals").

Several extensions are particularly relevant to the language design explored in this thesis:

- *Multi-memory* allows a module to use multiple linear memories, for example to separate private data from memory shared with the host.
- *Reference types* let a module hold and pass opaque references. An `externref` can refer to a host object, such as a DOM node, without representing it as a manually managed integer handle.
- *Multi-value* allows functions and blocks to produce multiple results. This can avoid the need to pass an output pointer when a function needs to return several values.
- *SIMD* introduces the `v128` value type and vector instructions that can perform operations on multiple numeric lanes in parallel.
- *Exception handling* uses tags to distinguish typed exceptions that a module can throw and catch. These are separate from traps, which represent execution failures.

These entities and instructions are concepts a developer may want to express in source code. A language may expose them directly, provide access through libraries or compiler-specific mechanisms, or leave them unavailable.

== Comparing languages <sec:method>

Eight languages are compared along two axes. *Exposure* asks which WebAssembly features a developer can name, configure, and control from source code. *Integration* asks how the resulting module is run, called, packaged, and debugged, and how large it is. These axes describe access to the platform and its tooling; hiding platform details may be a deliberate language choice. They are reported separately (@sec:exposure, @sec:integration).

*Languages.* Eight language columns were studied (@tbl:languages). C and C++ share a column because they use one toolchain. MoonBit has two backends, `wasm` and `wasm-gc`, that cannot be combined in one module; each probe is run on both and a feature that only the other backend offers is counted as an obstacle. The set was chosen for current use as a WebAssembly target and for variety in design intent. It is not complete: Emscripten, Go's standard compiler and Dart are known omissions.

#figure(
  booktable(
    columns: (auto, 1fr, auto, auto),
    align: (left, left, left, left),
    table.header([Language], [Version], [Memory model], [Route]),
    table.hline(stroke: 0.5pt),
    [Rust],
    [1.99.0],
    [linear],
    [LLVM],
    [Zig],
    [0.16.0],
    [linear],
    [LLVM],
    [C/C++],
    [clang 23.1.0 (wasi-sdk 34.0)],
    [linear],
    [LLVM],
    [Swift],
    [6.4.0 (Embedded Swift)],
    [linear],
    [LLVM],
    [MoonBit],
    [`moon` 0.1.20260920, `moonc` v0.10.14],
    [linear / Wasm GC],
    [own backend],
    [AssemblyScript],
    [0.28.20],
    [linear + runtime GC],
    [Binaryen],
    [TinyGo],
    [0.42.0 (Go 1.27.1)],
    [linear + runtime GC],
    [LLVM],
    [Kotlin],
    [2.4.21 (Kotlin/Wasm)],
    [Wasm GC],
    [own backend],
  ),
  caption: [The languages compared, in the order used by all figures: grouped by memory model.],
) <tbl:languages>

The memory-model column distinguishes garbage collection implemented by a language runtime in linear memory from WebAssembly's own GC features. The route column records the compiler infrastructure used to produce the module.

*How it was verified.* Each test uses a small program based on the language's documentation and built with a toolchain pinned in a container. A checker inspects the compiled `.wasm` or runs it under V8, Wasmtime, or Node. The results are a snapshot. The programs, checker, and per-cell evidence are available in the project repository #fnote("wx-study"). #todo[pin commit hash or tag]

== Exposure <sec:exposure>

=== What is tested <sec:exposure-tests>

Thirty features from the released versions of the specification (1.0, 2.0 and 3.0) were probed. A feature is either a piece of module structure (a memory, a global, a tag) or a family of instructions probed as one unit, such as SIMD. For every feature and language, a small program tries to make the feature appear in the compiled module. Each pair receives one result, which says where the feature lives relative to the language (@tbl:vocabulary); a result reached with a caveat carries a flag, for example *partial* when only part of the feature can be controlled.

#figure(
  booktable(
    columns: (auto, auto, auto, 1fr),
    align: (left, center, center, left),
    table.header([Result], [In source], [Checked by the language's types], [Meaning]),
    table.hline(stroke: 0.5pt),
    [Native],
    [yes],
    [yes],
    [a language construct, or a typed library or intrinsic function; the compiler may choose the encoding],
    [Annotation],
    [yes],
    [yes],
    [an attribute on an ordinary construct],
    [Config],
    [no],
    [no],
    [a build flag, configuration file or linker argument],
    [Inline assembly],
    [yes],
    [no],
    [assembly or Wasm text written by hand],
    [Absent],
    [n/a],
    [n/a],
    [no way found; _confirmed_ if documentation or compiler rejects it, _not found_ otherwise],
  ),
  caption: [The vocabulary used to classify every cell of the comparison.],
) <tbl:vocabulary>

=== How it is rated <sec:exposure-rating>

The counts of results are the evidence. A single score between 0 and 1 per language summarises them: each feature counts fully, partially or not at all, is discounted for every obstacle on the way (a build option, hand-written assembly, an experimental interface, an unstable compiler, a runtime shipped in every module, a restricted host, or a different backend), and counts more if it belongs to the module core that every program uses. A feature reached fully scores 1, partially 0.5 and not at all 0. The score of a cell is that reach times the factor of each obstacle on its way (@tbl:obstacles), and the score of a language is the weighted mean of its cells over the thirty features, with weight 3 for the module core, 2 for common extensions and 1 for specialised ones.

#figure(
  booktable(
    columns: (1fr, auto),
    align: (left, center),
    table.header([Obstacle], [Factor]),
    table.hline(stroke: 0.5pt),
    [Build configuration], [0.90],
    [Experimental interface], [0.85],
    [Unstable compiler], [0.80],
    [Restricted host], [0.80],
    [Extra runtime in the module], [0.70],
    [Inline assembly], [0.50],
    [Different backend], [0.35],
  ),
  caption: [Obstacles to reaching a feature and their factors, from the least to the most damaging.],
) <tbl:obstacles>

The discounts and weights are the author's choice: the order of the obstacles is argued in the study, and the factors are read off that order. They are meant to order the languages roughly, not to measure them to the second decimal.

*Sensitivity.* The ranking is repeated 2000 times, with a fixed seed, with the coefficients moved at random: the partial reach by up to ±0.2, the damage of every obstacle (one minus its factor) by a common factor between 0.5 and 1.5 and by ±15% each, with the order of the obstacles kept, and every feature weight by a factor between 0.5 and 2. A rank range is the best and worst rank of a language over the draws, and an order of two languages counts as robust when it holds in at least 95% of them. This is the sensitivity of the author's index to its own coefficients, not a confidence interval for the quality of a language.

=== Results <sec:results>

@fig:matrix shows how each language reaches each feature, distinguishing source constructs from configuration, assembly, and features for which no route was found.

#figure(
  ch.matrix-figure(),
  kind: "chart",
  caption: [How each language reaches each of the #ch.n-features WebAssembly features, grouped by memory model and by specification version. The cell shows the best route found. Features in bold correspond to WebAssembly's module entities (@sec:synthesis).],
  placement: auto,
) <fig:matrix>

For #ch.construct-in-none.len() of the #ch.n-features features, no language offers a source construct or annotation. These gaps include control over memory limits and data placement, both of which affect the structure of the resulting module.

*Coverage differs between languages.* @fig:reach counts how each language reaches the thirty tested features. Even the broadest, which reaches #ch.broadest.reached of #ch.n-features, reaches #(ch.broadest.reached - ch.broadest.counts.reachedVia.language) of them only through configuration or assembly.

#figure(
  image("../../figures/build/reach-en.png", width: 100%, alt: "Bar chart: for each language, how many of 30 features are reached as a construct or annotation, through build configuration, as inline assembly, or not at all. Rust: 11, 5, 8, 6. Zig: 8, 5, 10, 7. C/C++: 13, 6, 5, 6. Swift: 9, 5, 0, 16. MoonBit: 12, 2, 2, 14. AssemblyScript: 12, 3, 0, 15. TinyGo: 5, 5, 0, 20. Kotlin: 11, 0, 0, 19."),
  kind: "chart",
  caption: [Number of the #ch.n-features features each language reaches as a language construct or annotation, through build configuration, as inline assembly, or not at all.],
) <fig:reach>

*The profiles are complementary, not nested.* @fig:versions shows that languages built on linear memory reach more of the sampled 1.0 and 2.0 features, while Kotlin reaches the GC and exception features of 3.0. No language reaches both the GC features and the tested linear-memory features in full. MoonBit offers both groups on separate backends that cannot be combined in one module. This is the pattern described in the introduction: using both usually means combining languages.

#figure(
  ch.version-figure(),
  kind: "chart",
  caption: [Features reached, out of those probed, per specification version.],
) <fig:versions>

@fig:exposure summarises coverage and the obstacles to reaching each feature. The rank ranges show how the ordering changes when the scoring coefficients are varied.

#figure(
  image("../../figures/build/exposure-en.png", width: 100%, alt: "Bar chart of the exposure score from 0 to 1 with the range of each rank: C/C++ 0.71 (rank 1), Rust 0.64 (2–3), Zig 0.59 (2–4), AssemblyScript 0.57 (2–4), Swift 0.43 (5–8), MoonBit 0.39 (5–9), TinyGo 0.34 (6–9), Kotlin 0.32 (5–9)."),
  kind: "chart",
  caption: [Exposure score (0 to 1) per language, ordered, with the range of its rank when the scoring coefficients are varied at random 2000 times. The ranking covers the eight languages of the study and WX, nine entries in all.],
) <fig:exposure>

== Integration <sec:integration>

=== What is tested <sec:integration-tests>

Access to platform features is only part of using WebAssembly: the resulting module must also work with its host. Five integration criteria are scored (@tbl:criteria). They use three small programs with host scripts shared across languages: `life` (computation on linear memory), `cat` (a WASI command that copies standard input to standard output), and `words` (a string in, a record out).

#figure(
  booktable(
    columns: (auto, 1fr, auto),
    align: (left, left, left),
    table.header([Criterion], [Test], [Scored by]),
    table.hline(stroke: 0.5pt),
    [I1 WASI],
    [`cat` is built for the WASI target and run under Wasmtime],
    [route],
    [I2 Component Model],
    [`words` is built as a component with a typed interface and called under Wasmtime; only direct support counts, not hand-written glue],
    [route],
    [I3 JS bindings],
    [`words` is called from Node with a string and returns an object, through the glue the language's tooling generates],
    [route],
    [I4 Debuggability],
    [a debug build of `life` is checked for a name section, DWARF or a source map, and a trap whose stack names the source function],
    [full or partial],
    [I5 Size],
    [all three programs are built as a smallest and as a default build and the size is the smaller of the raw module and the module after `wasm-opt -Oz`],
    [bytes],
  ),
  caption: [The integration criteria.],
) <tbl:criteria>

=== How it is rated <sec:integration-rating>

Criteria I1 to I3 are scored by *route*, from best to worst: built into the language's own toolchain, an official extra tool (from the language's project or the Bytecode Alliance), a community tool, or glue the developer writes by hand. A route without direct support scores 0 (@tbl:routes).

#figure(
  booktable(
    columns: (1fr, auto),
    align: (left, center),
    table.header([Route], [Factor]),
    table.hline(stroke: 0.5pt),
    [Built into the language's toolchain], [1.00],
    [Official extra tool], [0.85],
    [Community tool], [0.70],
    [Written by hand], [0.50],
  ),
  caption: [Routes to an integration capability and their factors. A route without direct support scores 0.],
) <tbl:routes>

*Cells and size.* A cell is its reach times the route factor times the factors of its obstacles, as for exposure; in I4 it is full with names plus DWARF or a source map, and partial with names only. For a program of size $s$ the size score is $1 - log_10(s / s_min) / 3$, limited to the range 0 to 1, where $s_min$ is the smallest size of that program among the languages. Size is scored on a log scale, so that one very large runtime does not flatten the rest: a build 1000 times the smallest scores 0. The size score of a language is the mean over its three programs and both builds, the smallest and the default.

The integration score is the weighted mean of I1 to I5, with the weights given in @fig:integration. As with exposure, these coefficients are the author's choice and the score is only a summary.

=== Results <sec:integration-results>

@fig:integration reports the five scored criteria and their weighted summary.

#figure(
  ch.integration-figure(),
  kind: "chart",
  caption: [Score of each language on the five scored integration criteria (0 to 1; – means no direct support) and the integration score, their weighted mean. The weight of each criterion is given under its name.],
  placement: auto,
) <fig:integration>

All eight languages run `cat` as a WASI command, six with their ordinary toolchain. Component Model support is less uniform: only #ch.order.filter(l => ch.integ.at(l).per.I2 > 0).len() have a direct route, all through an official extra tool. JavaScript integration also varies, from generated bindings to hand-written glue.

Module size also varies substantially: the smallest builds of `life` range from 408 bytes for AssemblyScript to 61 KB for Kotlin. The sizes in bytes, including those of the default builds, are in the data of the study #fnote("wx-study").
== Reading the scores <sec:reading-scores>

*How to read these numbers.* They are a snapshot of the probes written for this study, run against pinned toolchains, and the author is not equally expert in every language. The probe set samples the specification rather than covering it, the integration programs are small, and a cell marked _not found_ means no way was found, which is weaker than impossible. Some routes are counted conservatively: a hand-built component is not support for components. The study does not test whether a language checks the host boundary for safety. The scores summarise the counts and are not a verdict on any language.

== Synthesis and design questions <sec:synthesis>

The recurring gaps concern module structure and newer extensions. These may reflect deliberate choices suited to a language's audience. For WX, they identify concepts that a language built around WebAssembly could make explicit.

The #ch.entity-features.len() features in bold in @fig:matrix are those that correspond to WebAssembly's module entities: the memory section, multiple memories, globals, tables (indirect calls, import and export, and multiple tables) and exception tags. No language offers a construct for more than #ch.max-entity-constructs of them.

The comparison concerns each language together with its tested toolchain. It establishes which routes were found, but does not by itself identify whether a gap comes from the language, its backend, or its linker.

The gaps lead to five questions that guide WX's design:

+ *Declared entities.* Can memories, globals, imports, and exports be typed source constructs, rather than controlled through build options or assembly?
+ *Several memories.* Can a program use several memories, with memory identity represented in types and checked by the compiler?
+ *No imposed model.* Can programs adopt capabilities as needed without committing to a fixed runtime or memory-management strategy?
+ *Checked access to instructions.* Can raw WebAssembly instructions be exposed through typed operations that the compiler checks?
+ *Declared host boundary.* Can source declarations make the interface to the host explicit and reduce dependence on hand-written glue?
