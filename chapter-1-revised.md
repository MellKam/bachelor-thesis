## Chapter 1 - Introduction

### 1.1 Motivation

WebAssembly (Wasm) is a portable bytecode format designed to execute safely inside a sandboxed environment. Its origins are closely connected to asm.js, a restricted subset of JavaScript that made it practical to compile lower-level languages such as C and C++ for the browser. WebAssembly took this idea further by introducing a dedicated binary format and execution model rather than relying on JavaScript as the transport format.

Although WebAssembly began as a technology for the Web, its use has expanded well beyond the browser. Standalone runtimes make it useful for server-side and serverless workloads, where fast startup and strong isolation are valuable properties, and the same isolation model makes it attractive as an extension format for running third-party or otherwise untrusted code inside a controlled sandbox.

At the same time, WebAssembly is still evolving. Its core remains deliberately small, while additional capabilities are added through extensions. Features such as garbage collection, multiple memories, exception handling, and emerging stack-switching support expand the range of programming models WebAssembly can support directly. The Component Model is also developing a higher-level way for independently compiled components to interact across language boundaries.

Together, these extensions give WebAssembly more ways to represent memory and control flow than any single language needs. It is becoming less a narrow compilation target and more a general-purpose platform — and realizing that depends on how well the languages that target it expose what it actually offers.

### 1.2 Problem statement

That many different languages can target WebAssembly is by design, not a problem to solve — hosting many programming models is what the platform is for. The actual problem is that every one of those languages reaches WebAssembly through its own model: a compiler's authors pick a paradigm, and a developer's code is shaped by that paradigm before it becomes WebAssembly. The platform's own constructs are never reached directly, only through whatever a given language's design chose to keep.

This mediation has two consequences. Developers often have little visibility into which WebAssembly constructs their code actually produces, since the language's abstractions sit between the two. And wherever a language's model falls short of what the platform offers, closing the gap tends to require extra tooling — binding generators, code transformers, annotation processors — layered on top rather than built into the language itself.

This holds even for languages designed for WebAssembly from the start. They too settle on a programming model — a memory-management strategy, a set of abstractions, a particular notion of safety — and expose that model instead of the platform's own constructs. Being designed for WebAssembly has so far meant targeting it well, not exposing what it actually offers.

This creates room for a different kind of language: not one more paradigm alongside the others, but one whose purpose is to stay out of the way. Rather than committing to a particular runtime or memory-management model, it could let developers combine the platform's capabilities as needed — directly, without writing WAT by hand or working through a paradigm imposed on top of them.

Such a language could represent WebAssembly's own concepts — memories, globals, tables, imports, exports, and tags — as typed constructs in the source language. These constructs would have a direct and understandable correspondence to the resulting Wasm module, allowing developers to work at a higher level without losing sight of what the compiler produces.

### 1.3 Goals

The goal of this thesis is not to replace existing languages. It is to explore how to make writing code for the WebAssembly platform a first-class experience. Demonstrating this means showing that such a design's core mechanisms can be implemented in a working compiler, compose consistently, and are sufficient to write practical programs.

The implementation follows these design principles:

1. **Typed platform model.** The WebAssembly concepts are first-class language constructs. The programmer works directly with the platform's own model, and any typed construct wrapping a platform concept is zero-cost with no runtime overhead.
2. **Minimal core, opt-in capabilities.** The baseline language is as lean as core WebAssembly. No memory-management model, runtime, or extension is forced onto the developer. Programs adopt additional capabilities incrementally, as needed.
3. **Uniform mechanisms.** There is one mechanism for each kind of problem. New WebAssembly features, such as garbage collection or stack switching, should be expressible through existing mechanisms instead of requiring a new category of language construct.

### 1.4 Scope

The main scope of this thesis is to design such a language and show how the idea works in practice. The implementation therefore serves as a proof of concept, built to show whether the language is practical to write real programs in, while objectively outlining its limitations and the future work needed to fully implement the idea.

It focuses on the foundations needed to demonstrate the design's main ideas: parsing, semantic analysis, type inference, traits, modules, WebAssembly code generation, and optimization passes such as inlining and dead-code elimination.

It also implements several WebAssembly-specific concepts central to the thesis, including memory and global declarations backed by compiler-generated trait implementations, memory-aware pointers, and explicit import and export declarations. The surrounding tooling supports multi-file projects, packages and dependencies, a language server, and a formatter.

Practicality is tested through a set of example programs, each exercising a different part of the design, including programs that use the operating system through WASI Preview 1. The results are checked against the principles in Section 1.3, and any limitations found along the way are reported as findings.

More advanced ideas, including effect tracking, WebAssembly GC integration, stack switching, and parts of the memory-safety model, remain design work or future extensions.
