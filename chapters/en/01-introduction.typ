#import "../../template.typ": todo, unnumbered
#import "../../bibliography.typ": fnote

#unnumbered[Introduction] <ch:introduction>

#heading(level: 2, numbering: none, outlined: false)[Motivation] <sec:motivation>

WebAssembly (Wasm) is a portable bytecode format designed to execute safely inside a sandboxed environment. It grew out of asm.js, a restricted subset of JavaScript for compiling C and C++ for the browser, but has its own binary format and execution model #fnote("haas2017")#super[,]#fnote("asmjs").

Although WebAssembly began as a technology for the Web, its use has expanded well beyond the browser. Standalone runtimes make it useful for server-side and serverless workloads, where fast startup and strong isolation are valuable properties, and the same isolation model makes it attractive as an extension format for running third-party or otherwise untrusted code inside a controlled sandbox.

At the same time, WebAssembly is still evolving. Its core remains deliberately small, while additional capabilities are added through extensions. Features such as garbage collection, multiple memories, exception handling, and emerging stack-switching support expand the range of programming models WebAssembly can support directly. The Component Model is also developing a higher-level way for independently compiled components to interact across language boundaries.

As these extensions arrive, WebAssembly can support more ways of writing programs. Developers, however, usually work through a source language rather than writing WebAssembly directly. One language may build on linear memory, while another garbage collection. Using both usually means combining languages, even though the platform supports both.

#heading(level: 2, numbering: none, outlined: false)[Problem statement] <sec:problem>

That many different languages can target WebAssembly is by design, not a problem to solve — hosting many programming models is what the platform is for. The problem is that developers reach WebAssembly through a language's own model: its authors choose a paradigm, and that paradigm shapes what the developer can express before the code becomes WebAssembly. The platform's constructs are available only to the extent that the language and its toolchain expose them.

This has two consequences. Developers often have little visibility into which WebAssembly constructs their code produces, since the language's abstractions sit between the two. And where a language's model falls short of what the platform offers, closing the gap tends to require build options, binding generators, or code transformations outside the language itself.

This holds even for languages designed for WebAssembly from the start. They too settle on a programming model — a memory-management strategy, a set of abstractions, a particular notion of safety — and expose that model instead of the full range of the platform's constructs. Being designed for WebAssembly has so far meant targeting it well, not exposing everything it offers.

This motivates a language organized around WebAssembly's resources, with allocation and runtime policies left to libraries and applications. Memories, globals, tables and tags would be typed source constructs. The long-term aim is to combine more of the platform's capabilities in one language; this thesis investigates that foundation through memories, globals, functions and selected instructions.

#heading(level: 2, numbering: none, outlined: false)[Goals] <sec:goals>

The goal of this thesis is to investigate whether a source language can expose WebAssembly resources directly and check their use through its type system. The work tests whether the core mechanisms can be implemented in a working compiler, compose consistently, and support practical example programs.

The implementation follows these design principles:

+ *Typed platform model.* WebAssembly's concepts are first-class language constructs. The programmer reasons in the platform's own model, and a typed construct that wraps a platform concept is designed to add no runtime cost.
+ *Minimal core, opt-in capabilities.* The baseline language is as lean as core WebAssembly. No memory-management model, runtime, or extension is forced onto the developer. Programs adopt additional capabilities incrementally, as needed.
+ *Uniform mechanisms.* The same type-system mechanisms are reused for module entities, values, calls, and instructions. This shared foundation is intended to scale to other WebAssembly features without requiring a separate language mechanism for each one.

#heading(level: 2, numbering: none, outlined: false)[Research questions] <sec:research-questions>

The comparison of existing languages in @ch:background ends with five questions, which the rest of the thesis answers for WX. Can memories, globals, imports and exports be typed constructs of the source, and not settings of a build or assembly? Can a program use several memories, with the identity of a memory part of the types and checked by the compiler? Can programs take on capabilities as needed, without a fixed runtime or memory-management strategy? Can raw instructions be offered as typed operations that the compiler checks? Can source declarations state the interface to the host, so that less glue has to be written by hand? The questions are stated in full in @sec:synthesis, and the conclusion returns to them.

#heading(level: 2, numbering: none, outlined: false)[Methods] <sec:methods>

Four methods are used. A comparative study tests eight languages on thirty features of the WebAssembly specification and on five criteria of integration with hosts and tooling, using small programs built with pinned toolchains and checked automatically (@ch:background). The design of WX is then derived from the structure of the platform: each kind of entity, value, call and instruction is examined in turn, and the mechanism that represents it in the type system is described, with an example and its compiler output (@ch:items to @ch:hosts). The design is implemented in a proof-of-concept compiler written in Rust, whose structure and tests are described in @ch:implementation. Finally, the design is evaluated with the same feature probes and integration criteria that were applied to the other languages, with the sizes of the modules produced, and with example programs that use the mechanisms together (@ch:evaluation).

#heading(level: 2, numbering: none, outlined: false)[Design influences] <sec:design-influences>

WX draws on several language traditions. Rust's type system, especially its traits and generics, inspired WX's approach to describing what a WebAssembly entity can do; Haskell's related type classes were another influence #fnote("rust-traits")#super[,]#fnote("haskell-type-classes")#super[,]#fnote("wadler1989"). Zig's explicit control over allocation influenced the decision to leave allocation and runtime choices to the programmer #fnote("zig-allocators"). ML-family languages influenced WX's expression-oriented style, type inference, and treatment of functions as composable values #fnote("milner1997").

The syntax follows a Rust-like grammar while using WebAssembly's own vocabulary where it helps explain the resulting module. Names such as `memory`, `global`, `func`, `import`, and `export` are familiar from WAT, WebAssembly's text format #fnote("wasm-spec-text"). WIT, the interface definition language of the Component Model, also influenced the way WX describes boundaries between a program and its host #fnote("wasm-wit"). These influences serve the same aim: to make the platform visible in source code without requiring developers to write WebAssembly directly.

#heading(level: 2, numbering: none, outlined: false)[Contributions] <sec:contributions>

The thesis makes the following contributions:

+ *A comparison of how languages expose WebAssembly* (@ch:background). Eight languages are tested on thirty features of the specification and on how their modules integrate with hosts and tooling. The study uses small programs built with pinned toolchains and checks their output automatically. Its programs and evidence are published so that the comparison can be repeated.
+ *Items: the platform's entities as types* (@ch:items). In WX, every memory, global and function is an item with its own zero-sized type, and a trait that the compiler implements describes what the item can do. A pointer type says which memory it points into. This makes several memories, and code that is generic over memories, part of the type system.
+ *The same mechanism for values and calls* (@ch:stack-values, @ch:calls). A trait computed by the compiler describes how any WX type is held on the WebAssembly stack. It decides which types a global can hold, checks reinterpretation between types, and makes a function's WebAssembly signature follow directly from its WX signature.
+ *Instructions as typed functions* (@ch:intrinsics). Selected WebAssembly instructions are exposed as functions in the standard library. An intrinsic that names an entity takes the entity's item, never an integer index.
+ *A compiler* written in Rust that implements this design, with tests for each part. Every error message shown in the design chapters was produced by it.

#heading(level: 2, numbering: none, outlined: false)[Scope] <sec:scope>

The thesis focuses on WX's language design and a proof-of-concept implementation. The compiler and example programs show how the design works in practice; the evaluation examines its strengths and limitations.

The implementation covers the following:

+ *Language base.* Parsing, semantic analysis, a type system with inference, traits, and modules.
+ *Memory and pointers.* The part most central to the thesis. Memories are declared in the source, and pointers carry the memory they point into.
+ *Globals.* Declared in the source as typed constructs, like memories.
+ *Imports and exports.* Explicit declarations in the source.
+ *Code generation and optimization.* WebAssembly code generation, with passes such as inlining and dead-code elimination.

Practicality is tested through a set of example programs, each exercising a different part of the design, including programs that use the operating system through WASI Preview 1. The results are checked against the principles listed under Goals, and any limitations found along the way are reported as findings.

Further work could extend the model to effect tracking, WebAssembly GC, stack switching, and fuller memory-safety checks.

#heading(level: 2, numbering: none, outlined: false)[Structure of the thesis] <sec:structure>

@ch:background introduces the structure of a WebAssembly module and compares how eight languages expose it. The comparison ends with five questions that guide the language design. @ch:items shows how WX represents memories, globals, and functions as items with their own types, and how pointers identify their memory. @ch:stack-values describes stack representation, @ch:calls applies it to function calls, and @ch:intrinsics explains typed instruction access. @ch:bodies describes function bodies, and @ch:hosts combines these mechanisms in browser and WASI programs. @ch:implementation presents the compiler's architecture and tests. @ch:evaluation reports feature coverage, integration and module sizes, then discusses limitations and future work. The conclusion returns to the research questions.
