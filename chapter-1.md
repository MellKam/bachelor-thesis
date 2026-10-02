## Chapter 1 - Introduction

### 1.1 Motivation

WebAssembly (Wasm) is a portable bytecode format designed to execute safely inside a sandboxed environment. Its origins are closely connected to asm.js, a restricted subset of JavaScript that made it practical to compile lower-level languages such as C and C++ for the browser. WebAssembly took this idea further by introducing a dedicated binary format and execution model rather than relying on JavaScript as the transport format.

Although WebAssembly began as a technology for the Web, its use has expanded well beyond the browser. Standalone runtimes make it useful for server-side and serverless workloads, where fast startup and strong isolation are valuable properties. It is also increasingly used as an extension format, allowing applications to execute third-party code inside a controlled sandbox, and the same isolation model makes it attractive for running other untrusted or dynamically produced workloads.

At the same time, WebAssembly is still evolving. Its core remains deliberately small, while additional capabilities are added through extensions. Features such as garbage collection, multiple memories, exception handling, and emerging stack-switching support expand the range of programs that can be expressed directly in Wasm. The Component Model is also developing a higher-level way for independently compiled components to interact across language boundaries.

As these capabilities mature and the surrounding tooling improves, WebAssembly could see broader adoption among regular developers rather than remaining primarily a specialized compilation target.

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

```
import "env" as env {
  
}

import("env", "abc") fn log(msg: &[u8]);
```