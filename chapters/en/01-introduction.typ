#import "../../template.typ": todo

= Introduction <ch:introduction>

== Motivation <sec:motivation>

WebAssembly (Wasm) is a portable bytecode format designed to execute safely inside a sandboxed environment. Its origins are closely connected to asm.js, a restricted subset of JavaScript that made it practical to compile lower-level languages such as C and C++ for the browser. WebAssembly took this idea further by introducing a dedicated binary format and execution model rather than relying on JavaScript as the transport format. #todo[cite asm.js and the original WebAssembly paper]

Although WebAssembly began as a technology for the Web, its use has expanded well beyond the browser. Standalone runtimes make it useful for server-side and serverless workloads, where fast startup and strong isolation are valuable properties, and the same isolation model makes it attractive as an extension format for running third-party or otherwise untrusted code inside a controlled sandbox.

At the same time, WebAssembly is still evolving. Its core remains deliberately small, while additional capabilities are added through extensions. Features such as garbage collection, multiple memories, exception handling, and emerging stack-switching support expand the range of programming models WebAssembly can support directly. The Component Model is also developing a higher-level way for independently compiled components to interact across language boundaries.

As these extensions arrive, WebAssembly can do more than before. But developers do not use WebAssembly directly. They use it through a programming language, and each language builds on only part of the platform. One is built around linear memory, another around garbage collection. Using both usually means combining languages, even though the platform supports both.

== Problem statement <sec:problem>

That many different languages can target WebAssembly is by design, not a problem to solve — hosting many programming models is what the platform is for. The actual problem is that every one of those languages reaches WebAssembly through its own model: a compiler's authors pick a paradigm, and a developer's code is shaped by that paradigm before it becomes WebAssembly. The platform's own constructs are rarely reached directly, only through whatever a given language's model and toolchain chose to keep.

This mediation has two consequences. Developers often have little visibility into which WebAssembly constructs their code actually produces, since the language's abstractions sit between the two. And wherever a language's model falls short of what the platform offers, closing the gap tends to require extra tooling — binding generators, code transformers, annotation processors — layered on top rather than built into the language itself.

This holds even for languages designed for WebAssembly from the start. They too settle on a programming model — a memory-management strategy, a set of abstractions, a particular notion of safety — and expose that model instead of the platform's own constructs. Being designed for WebAssembly has so far meant targeting it well, not exposing what it actually offers.

This creates room for a different kind of language. It would not add another paradigm alongside the others. It would take the platform's own model as its starting point, so that no memory-management strategy or runtime is imposed on top. Memories, globals, tables and tags would be typed constructs in the source, and developers would reason in the same concepts the platform uses. That lets one language combine capabilities that today come from different languages. The Component Model can join separately written components, but each is still written in some language's model. The compiler stays free to optimize anything that is not visible to the host.

== Goals <sec:goals>

The goal of this thesis is not to replace existing languages. It is to explore how to make writing code for the WebAssembly platform a first-class experience. Demonstrating this means showing that such a design's core mechanisms can be implemented in a working compiler, compose consistently, and are sufficient to write practical programs.

The implementation follows these design principles:

+ *Typed platform model.* WebAssembly's concepts are first-class language constructs. The programmer reasons in the platform's own model, and a typed construct that wraps a platform concept is designed to add no runtime cost.
+ *Minimal core, opt-in capabilities.* The baseline language is as lean as core WebAssembly. No memory-management model, runtime, or extension is forced onto the developer. Programs adopt additional capabilities incrementally, as needed.
+ *Uniform mechanisms.* There is one mechanism for each kind of problem. New WebAssembly features, such as garbage collection or stack switching, should be expressible through existing mechanisms instead of requiring a new category of language construct.

== Contributions <sec:contributions>

The thesis makes the following contributions:

+ *A comparison of how languages expose WebAssembly* (@ch:background). Eight languages are tested on thirty features of the specification and on how easy their modules are to use. Every result comes from a small program, compiled with a pinned toolchain and checked automatically. The study is published with all its programs, so it can be repeated.
+ *Items: the platform's entities as types* (@ch:items). In WX, every memory, global and function is an item with its own zero-sized type, and a trait that the compiler implements describes what the item can do. A pointer type says which memory it points into. This makes several memories, and code that is generic over memories, part of the type system.
+ *The same mechanism for values and calls* (@ch:stack-values, @ch:calls). A trait computed by the compiler describes how any WX type is held on the WebAssembly stack. It decides which types a global can hold, checks reinterpretation between types, and makes a function's WebAssembly signature follow directly from its WX signature.
+ *Instructions as typed functions* (@ch:intrinsics). WebAssembly instructions are functions in the standard library. An instruction that names an entity takes the entity's item, never an integer index.
+ *A compiler* written in Rust that implements this design, with tests for each part. Every error message shown in the design chapters was produced by it.

== Scope <sec:scope>

The main scope of this thesis is to design such a language and show how the idea works in practice. The implementation therefore serves as a proof of concept, built to show whether the language is practical to write real programs in, while objectively outlining its limitations and the future work needed to fully implement the idea.

The implementation covers the following:

+ *Language base.* Parsing, semantic analysis, a type system with inference, traits, and modules.
+ *Memory and pointers.* The part most central to the thesis. Memories are declared in the source, and pointers carry the memory they point into.
+ *Globals.* Declared in the source as typed constructs, like memories.
+ *Imports and exports.* Explicit declarations in the source.
+ *Code generation and optimization.* WebAssembly code generation, with passes such as inlining and dead-code elimination.

During this thesis the type checker was rewritten from scratch. The design chapters describe the language as the new type checker implements it. The code generator worked with the first type checker and is being connected to the new one.

#todo[Update this paragraph when code generation works again on the new type checker.]

Practicality is tested through a set of example programs, each exercising a different part of the design, including programs that use the operating system through WASI Preview 1. The results are checked against the principles in @sec:goals, and any limitations found along the way are reported as findings.

More advanced ideas, including effect tracking, WebAssembly GC integration, stack switching, and parts of the memory-safety model, remain design work or future extensions.

== Structure of the thesis <sec:structure>

@ch:background introduces the structure of a WebAssembly module and compares how eight languages expose it. The comparison ends with five design questions. @ch:items answers the first two: it shows how WX represents memories, globals and functions as items with their own types, and how pointers carry their memory. @ch:stack-values uses the same mechanism to describe how values are held on the WebAssembly stack. @ch:calls shows how function calls follow from that description. @ch:intrinsics shows how instructions become typed functions. #todo[Add the remaining chapters when they exist: the compiler, the evaluation (WX through the Chapter 2 probes), and the conclusion with future work.]
