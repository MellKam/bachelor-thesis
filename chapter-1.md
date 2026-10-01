## Chapter 1 - Introduction

### 1.1 Motivation

WebAssembly (Wasm) is a portable bytecode format designed to execute safely inside a sandboxed environment. Its origins are closely connected to asm.js, a restricted subset of JavaScript that made it practical to compile lower-level languages such as C and C++ for the browser. WebAssembly took this idea further by introducing a dedicated binary format and execution model rather than relying on JavaScript as the transport format.

Although WebAssembly began as a technology for the Web, its use has expanded well beyond the browser. Standalone runtimes make it useful for server-side and serverless workloads, where fast startup and strong isolation are valuable properties. It is also increasingly used as an extension format, allowing applications to execute third-party code inside a controlled sandbox, and the same isolation model makes it attractive for running other untrusted or dynamically produced workloads.

At the same time, WebAssembly is still evolving. Its core remains deliberately small, while additional capabilities are added through extensions. Features such as garbage collection, multiple memories, exception handling, and emerging stack-switching support expand the range of programs that can be expressed directly in Wasm. The Component Model is also developing a higher-level way for independently compiled components to interact across language boundaries.

As these capabilities mature and the surrounding tooling improves, WebAssembly could see broader adoption among regular developers rather than remaining primarily a specialized compilation target.

### 1.2 Problem statement

Most languages that target WebAssembly were not designed around it. Instead, they bring an existing programming model to the platform and translate that model into Wasm. This works well for portability, but it also means that a language usually exposes only the parts of WebAssembly that fit naturally into its existing design.

The issue is therefore not that existing languages cannot compile to WebAssembly, but that they usually expose it through a programming model chosen in advance. WebAssembly itself leaves considerably more room for choice. Linear memory and garbage-collected references can coexist, multiple memories can serve different purposes, and extensions can introduce new forms of control flow or interaction without requiring every program to adopt them.

WebAssembly is mostly recognized as compilation target, which indeed was a main reason of it, allowing developers to use familiar languages and tools while benefiting from Wasm's portability and sandboxing. It allows many langauges to bring their programming model and translate it to wasm primitives, but often this limits things you can actaully do and makes the actaul integration with platform awkward, requiring codegeneration and other tools to patch it. 

But if we abstract away from specific langauges we can see that WebAssembly gives consideable more root for choice. Linear memory and garbage-collected references can coexist, multiple memories can serve different purposes, and extensions can introduce new forms of control flow or interaction without requiring every program to adopt them.

Wasm itself is already a well-designed platform. It's already structured enough to reason about directly. What it lacks is just ergonomics: a syntax that isn't verbose WAT, and types system that will catch mistakes at compile time. A language designed around the platform, to treat WebAssembly not merely as a compilation target, but as the model from which its own abstractions are derived.


Languages that target WebAssembly serve different purposes. Many bring an existing programming model to the platform, allowing developers to use familiar languages and tools while benefiting from Wasm's portability and sandboxing. This is a reasonable approach, and it is not the aim of this thesis to replace it.

However, it leaves room for a different approach: a language designed around WebAssembly's own execution model. Wasm provides capabilities such as linear memories, garbage-collected references, and multiple memories, while its extension model allows programs to use additional features as they become available. These capabilities offer considerable flexibility, but using them directly often requires working with low-level instructions, compiler-specific mechanisms, or additional glue code.

The opportunity is to make this flexibility accessible through a language that provides more direct control over WebAssembly while streamlining the development experience. Rather than imposing a separate runtime or hiding the platform behind an existing programming model, such a language could expose Wasm's concepts through a coherent type system, concise syntax, and higher-level abstractions.

The goal is to explore how a language built around WebAssembly could make its capabilities easier to use without sacrificing control over the platform.


### 1.2 Problem statement

WebAssembly was designed as a portable compilation target for different programming languages, allowing developers to bring their existing tools and programming models to the platform while benefiting from its portability and sandboxing. Each language, however, exposes the platform through its own abstractions and runtime, so the capabilities a developer can reach depend as much on the language's design as on WebAssembly itself.

This is not inherently a problem. Different languages make different trade-offs, and no single language needs to expose every capability of the platform. However, WebAssembly provides a broader set of building blocks than any one programming model necessarily requires. Linear memory and garbage-collected references can coexist, multiple memories can serve different purposes, and extensions can introduce additional capabilities such as new control-flow mechanisms. These features create a space of possible language designs, with existing languages each covering a different part of it.

This creates an opportunity for a language designed around WebAssembly itself. Rather than committing to a particular runtime or memory-management model, it could allow developers to combine the platform's capabilities according to their needs. The challenge is to make this practical without requiring developers to write raw WAT or work around the assumptions built into their language's runtime.

The aim is therefore not to replace existing languages or expose every Wasm feature. It is to explore a language that provides typed, compile-time-checked constructs over WebAssembly's own execution model, giving developers direct control over the platform without an intervening layer of runtime decisions.












### 1.2 Problem statement

WebAssembly was designed as a portable compilation target for different programming languages, allowing developers to bring their existing tools and programming models to the platform while benefiting from Wasm's portability and sandboxing. Each language, however, exposes the platform through its own abstractions and runtime, influencing how directly and conveniently developers can access its capabilities.

This is not inherently a problem. Different languages make different trade-offs, and no single language needs to expose every capability of the platform. However, WebAssembly provides a broader set of building blocks than any one programming model necessarily requires. Linear memory and garbage-collected references can coexist, multiple memories can serve different purposes, and extensions can introduce additional capabilities such as new control-flow mechanisms. These features create a space of possible language designs, with existing languages exposing different parts of it and different levels of control over the underlying platform.

As a result, developers may have little visibility into which WebAssembly constructs their source code produces and how their language's abstractions map onto them. Accessing platform features or integrating with the host environment can also require additional tooling, such as binding generators, code transformers, or annotation processors, introducing another layer between the source code and the resulting Wasm module.

This creates an opportunity for a language designed around WebAssembly itself. Rather than committing to a particular runtime or memory-management model, it could allow developers to combine the platform's capabilities according to their needs. The challenge is to make this practical without requiring developers to write WAT directly or work around assumptions imposed by the language's abstractions and runtime.

Such a language could represent WebAssembly's own concepts, including memories, imports, exports, and tags, as typed constructs in the source language. These constructs would have a direct and understandable correspondence to the resulting Wasm module, allowing developers to work at a higher level without losing sight of what the compiler produces.

The aim is not to replace existing languages or require every language to expose every Wasm feature. It is to explore a language that makes WebAssembly easier to understand and work with, while preserving developers' control over the platform and the capabilities they choose to use.

### 1.3 Goals

The main goal is to demonstrate that this design works: that its core mechanisms can be implemented in a working compiler, compose consistently, and are sufficient to write practical programs.

The implementing should try to follow these design principles:

1. **Typed platform model.** WebAssembly concepts like globals, tables, imports, exports, and memories are first-class language constructs with types and compile-time checks. The programmer works directly with the platform's own model, and any typed construct wrapping a platform concept is zero-cost with no runtime overhead.
2. **Minimal core, opt-in capabilities.** The baseline language is as lean as core WebAssembly. No memory-management model, runtime, or extension is forced onto the developer. Programs adopt additional capabilities incrementally, as needed.
3. **Uniform mechanisms.** There is one mechanism for each kind of problem. New WebAssembly features, such as garbage collection or stack switching, should be expressible through existing mechanisms instead of requiring a new category of language construct.

**Evaluation.** The design is evaluated through the prototype and a set of example programs, each chosen to exercise a different part of the design. The programs serve as evidence of sufficiency: that the core mechanisms are enough to write real programs, including ones that use the operating system through WASI Preview 1. The results are assessed against the principles above, and limitations found along the way are reported as findings.

### 1.4 Scope

The language design presented in this thesis is broader than the working compiler prototype. The implementation focuses on the foundations needed to demonstrate its main ideas: parsing, semantic analysis, type inference, traits, modules, WebAssembly code generation, and optimization passes such as inlining and dead-code elimination.

It also implements several WebAssembly-specific concepts central to the thesis, including memory and global declarations backed by compiler-generated trait implementations, memory-aware pointers, and explicit import and export declarations. The surrounding tooling supports multi-file projects, packages and dependencies, a language server, and a formatter.

More advanced ideas, including effect tracking, WebAssembly GC integration, stack switching, and parts of the memory-safety model, remain design work or future extensions. The implementation therefore serves as a working proof of concept for the broader language design rather than its complete realization.