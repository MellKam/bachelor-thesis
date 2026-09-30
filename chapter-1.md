## Chapter 1 - Introduction

### 1.1 Motivation

WebAssembly (Wasm) is a portable bytecode format designed to execute safely inside a sandboxed environment. Its origins are closely connected to asm.js, a restricted subset of JavaScript that made it practical to compile lower-level languages such as C and C++ for the browser. WebAssembly took this idea further by introducing a dedicated binary format and execution model rather than relying on JavaScript as the transport format.

Although WebAssembly began as a technology for the Web, its use has expanded well beyond the browser. Standalone runtimes make it useful for server-side and serverless workloads, where fast startup and strong isolation are valuable properties. It is also increasingly used as an extension format, allowing applications to execute third-party code inside a controlled sandbox, and the same isolation model makes it attractive for running other untrusted or dynamically produced workloads.

At the same time, WebAssembly is still evolving. Its core remains deliberately small, while additional capabilities are added through extensions. Features such as garbage collection, multiple memories, exception handling, and emerging stack-switching support expand the range of programs that can be expressed directly in Wasm. The Component Model is also developing a higher-level way for independently compiled components to interact across language boundaries.

As these capabilities mature and the surrounding tooling improves, WebAssembly could see broader adoption among regular developers rather than remaining primarily a specialized compilation target.

### 1.2 Problem statement

Most languages that target WebAssembly were not designed around it. Instead, they bring an existing programming model to the platform and translate that model into Wasm. This works well for portability, but it also means that a language usually exposes only the parts of WebAssembly that fit naturally into its existing design.

AssemblyScript is one of the closest existing examples of a language designed specifically with Wasm as its primary target. It provides a familiar TypeScript-like programming model while compiling directly to WebAssembly. Its current runtime is built primarily around linear memory, with garbage collection implemented there rather than through Wasm GC, and manual memory management is provided through separate runtime configurations.

The issue is therefore not that existing languages cannot compile to WebAssembly, but that they usually expose it through a programming model chosen in advance. WebAssembly itself leaves considerably more room for choice. Linear memory and garbage-collected references can coexist, multiple memories can serve different purposes, and extensions can introduce new forms of control flow or interaction without requiring every program to adopt them.

What WebAssembly still lacks is something closer to what Java became for the JVM: a language designed around the platform from the beginning. Such a language would treat WebAssembly not merely as a compilation target, but as the model from which its own abstractions are derived. It could expose WebAssembly's capabilities directly while still providing a safer and more ergonomic programming experience than writing WAT by hand.

### 1.3 Goals

The goal of this thesis is to explore whether a language designed specifically around WebAssembly can expose its capabilities directly while still remaining practical for writing real programs.

The language should stay close enough to WebAssembly that learning it also helps the programmer understand the platform itself. Concepts such as memories, imports, exports, tags, and extensions should remain visible, while the language provides safer and more ergonomic ways to use them.

A central goal is consistency. New WebAssembly capabilities should, where possible, extend a small set of existing language mechanisms rather than introduce an unrelated abstraction for every feature. Garbage collection, multiple memories, or stack switching should feel like parts of the same language rather than separate subsystems.

Finally, the language should preserve WebAssembly's flexibility instead of committing the programmer to one fixed memory-management, runtime, or concurrency model. The programmer should be able to choose the capabilities needed by a particular program without falling back to unsafe intrinsics or ad-hoc glue code.

### 1.4 Scope

The language design presented in this thesis is broader than the working compiler prototype. The implementation focuses on the foundations needed to demonstrate its main ideas: parsing, semantic analysis, type inference, traits, modules, WebAssembly code generation, and optimization passes such as inlining and dead-code elimination.

It also implements several WebAssembly-specific concepts central to the thesis, including memory and global declarations backed by compiler-generated trait implementations, memory-aware pointers, and explicit import and export declarations. The surrounding tooling supports multi-file projects, packages and dependencies, a language server, and a formatter.

More advanced ideas, including effect tracking, WebAssembly GC integration, stack switching, and parts of the memory-safety model, remain design work or future extensions. The implementation therefore serves as a working proof of concept for the broader language design rather than its complete realization.