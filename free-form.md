## Chapter 1 - Introduction

### 1.1 Motivation

WebAssembly (Wasm) is a compact, portable binary instruction format for a stack-based virtual machine, standardized to execute safely inside a sandboxed environment. It occupies a niche similar to that of the Java Virtual Machine (JVM), but the two emerged from different design contexts. The JVM was developed alongside Oak and Java, and its runtime model reflects that language heritage, even though its class-file format can be targeted by other languages. WebAssembly, in contrast, was explicitly designed not to favor any particular programming-language family. Its initial implementation effort focused heavily on compiling C and C++ for the Web, but language independence was a goal of the platform from the beginning.

Running untrusted code safely in the browser is not a new problem. Java applets and Adobe Flash both relied on sandboxed runtimes, but suffered from security vulnerabilities and sandbox escapes in practice. Google's Native Client instead sandboxed native machine code, but required architecture-specific machinery and never became a broadly supported Web standard. WebAssembly addresses the same problem with a different design: a module starts with no direct access to the outside world and can only use functionality that the host explicitly makes available to it.

The core of WebAssembly is deliberately minimal and provides only the basic building blocks needed to construct more complex abstractions. Additional capabilities are introduced through extensions, so implementations and modules do not need to support or use every available feature. This allows Wasm to remain small at its core while still supporting features such as garbage collection, multiple memories, exception handling, and other extensions when they are needed.

WebAssembly is now supported by every major browser and is increasingly used outside the browser as well, including for application extensions, server-side execution, and sandboxed workloads. At the same time, the wider WebAssembly platform is still evolving. Important pieces such as stack switching and the Component Model continue to develop, and support for them across source languages and their tooling remains uneven.

As a result, WebAssembly today is both a mature execution format and a platform that is still being shaped. Most developers therefore encounter it indirectly through existing languages and toolchains, rather than as a platform whose own execution model and capabilities are exposed directly at the language level.

### 1.2 Problem statement

Most languages that target WebAssembly were not designed around WebAssembly itself. Instead, they bring an existing programming model to the platform and translate that model into Wasm. This works well for portability, but it also means that the language usually exposes only the parts of WebAssembly that fit naturally into its existing design.

AssemblyScript is a good example. It adopts a TypeScript-like language model together with a managed runtime and garbage-collected heap. Manual memory management is possible, but only through a separate runtime mode rather than as something that can be freely mixed with managed objects. The same tension becomes more visible as WebAssembly evolves: Memory64 and stack switching are currently considered uncertain by the project, while WASI and the Component Model are explicitly rejected in their current form.

The issue is therefore not that existing languages cannot compile to WebAssembly, but that they tend to expose it through assumptions inherited from somewhere else. WebAssembly itself offers a broader set of independent capabilities: linear memory and garbage-collected references can coexist, multiple memories can represent different storage regions, and extensions can introduce new forms of control flow or host interaction without requiring every program to adopt them.

What WebAssembly still lacks is something closer to what Java became for the JVM: a language designed around the platform from the beginning. Such a language would treat WebAssembly not merely as a compilation target, but as the model from which its own abstractions are derived, exposing its capabilities directly while still providing a higher-level and safer programming experience than writing WAT by hand.

### 1.3 Goals

The goal of this thesis is to explore whether a language designed specifically around WebAssembly can expose its capabilities directly while still remaining practical to use for real programs.

The language should stay close enough to WebAssembly that learning it also helps the programmer understand the platform itself. Concepts such as memories, imports, exports, tags, and other WebAssembly features should remain visible rather than being hidden behind an unrelated runtime model.

At the same time, these capabilities should be presented through safe and ergonomic abstractions. The programmer should not need to rely on unsafe intrinsics, generated glue code, or other ad-hoc mechanisms for ordinary use cases.

A central goal is consistency across WebAssembly's evolving feature set. New capabilities such as garbage collection, multiple memories, or stack switching should, where possible, be expressed using the same small set of language mechanisms rather than introducing a separate special case for every extension.

Finally, the language should preserve WebAssembly's flexibility instead of committing the programmer to one fixed memory-management, runtime, or concurrency model. The intention is to expose the platform's own building blocks at a higher level, while allowing each program to use only the features it actually needs.

### 1.4 Scope

The language design presented in this thesis is broader than the implemented prototype. The implementation focuses on the foundations needed to demonstrate the main ideas: parsing, semantic analysis, type inference, traits, modules, WebAssembly code generation, and basic optimizations such as inlining, dead-code elimination, and tree shaking.

It also implements several WebAssembly-specific concepts central to the thesis, including memory and global declarations backed by compiler-generated trait implementations, memory-aware pointers, and explicit import and export declarations. The surrounding tooling includes multi-file projects, package and dependency management, an LSP, and a formatter.

More advanced ideas, including effect tracking, WebAssembly GC integration, stack switching, and parts of the memory-safety model, remain design work or future extensions. The implementation should therefore be treated as a proof of concept for the broader language design rather than a complete realization of it.

