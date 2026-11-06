## Chapter 2 – Background and Related Work

### 2.1 The structure of a WebAssembly module

A WebAssembly program is delivered as a module: a self-contained unit that a host, such as a browser or a standalone runtime, loads and instantiates. A module consists of several kinds of entity. The main ones are:

* **Functions** are units of code, each with a typed signature.
* **Memories** are growable arrays of bytes.
* **Globals** hold a single value of a declared type and have a specified mutability.
* **Tables** hold references and are used mainly for indirect calls.
* **Tags** are nominal identifiers associated with type signatures, currently used for exceptions in WebAssembly.

A module can define these entities itself or import them from the host, and it can choose which of its entities to export [1].

This thesis uses WAT, the text format of WebAssembly, to illustrate modules. Parentheses group the different parts of a module, and names beginning with `$` identify entities. Instructions can be nested for readability. For example, `(call $log (i32.const 42))` passes the constant `42` to `$log`. Although written in nested form, the instructions execute in sequence: the constant is evaluated before the function is called.

Consider a small module:

```wat
(module
  (import "host" "log" (func $log (param i32)))
  (func $run
    (call $log (i32.const 42)))
  (export "run" (func $run)))
```

1. Import the function `"log"` from the `"host"` namespace and give it the internal name `$log`. It takes one `i32` parameter.
2. Define the function `$run`, which calls `$log` with the constant `42`.
3. Export `$run` under the name `"run"` so the host can access it.

#### The sandbox

This module cannot log anything by itself. The host must provide the imported function `host.log` when it instantiates the module. This illustrates a central aspect of WebAssembly's sandboxing model: a module can interact with its environment only through capabilities made available to it, such as imported functions and memories [2].

Three properties help enforce this boundary:

1. **Memory access is bounded.** A module can access only the memories available to it, whether defined internally or imported. Every memory access is bounds-checked, and an access outside the memory's current bounds traps.
2. **Structured control flow.** Branches follow WebAssembly's structured control-flow rules, and indirect calls are checked against the expected function type. These rules constrain execution, although they do not prevent bugs within the module.
3. **External access goes through imports.** Files, network access, and the system clock are not inherently available to a module. The host must expose such capabilities through imported functions or other interfaces.

The sandbox has important limits. It protects the host environment from direct, unauthorized access by the module, but it does not protect the module from its own bugs: linear memory is an untyped byte array, so a program can corrupt its own data while remaining within its memory bounds. Furthermore, an imported function can grant substantial authority. WASI, for example, defines interfaces for filesystem access and other system services, but the capabilities available to a module depend on what the host actually provides. WASI is not part of the core WebAssembly specification.

#### Extensions to the core

The WebAssembly core specification defines the platform's basic instruction set and execution model. Additional features have been incorporated into the specification over time, while other proposals continue to evolve. Some capabilities can be approximated using existing instructions and runtime support, but such workarounds may add complexity, reduce performance, or provide different safety guarantees. Others require new platform support.

Several extensions are particularly relevant to the language design explored in this thesis:

* **Multi-memory** allows a module to use multiple linear memories. These memories can serve different purposes, such as separating private data from memory shared with the host or keeping independently managed data in distinct address spaces. Multiple memories can also help when composing components that expect different memories.

* **Reference types** allow a module to hold and pass references to objects it cannot inspect directly. For example, a host can provide an opaque reference to an external object, such as a DOM node, through an `externref`. The module can pass the reference around or store it in a suitable table without representing it as a manually managed integer handle.

* **Multi-value** allows functions and blocks to produce multiple results. This can avoid the need to pass an output pointer when a function needs to return several values.

* **SIMD** introduces the `v128` value type and vector instructions that can perform operations on multiple numeric lanes in parallel.

* **Exception handling** allows a module to throw and catch typed exceptions. Tags identify exception types, allowing handlers to distinguish between different kinds of exceptions. This is separate from WebAssembly traps, which represent execution failures and are not ordinary catchable exceptions.

These features expand the set of capabilities available to WebAssembly programs, but their presence in the platform does not guarantee that a particular source language exposes them directly. A language may provide native constructs for a feature, require library support or compiler-specific mechanisms, or not support it at all.

These entities and instructions form the surface of the platform: the concepts a developer may want to express in a program. The rest of this chapter examines how different programming languages expose this surface, and how their design choices affect the way developers work with WebAssembly.

**References**

[1] WebAssembly Core Specification, Modules. https://webassembly.github.io/spec/core/syntax/modules.html
[2] WebAssembly Core Specification, Introduction. https://webassembly.github.io/spec/core/intro/introduction.html
[3] WebAssembly proposals overview. https://github.com/WebAssembly/proposals