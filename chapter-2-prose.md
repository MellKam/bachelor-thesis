## Chapter 2 - Background and Related Work

### 2.1 The structure of a WebAssembly module

A WebAssembly program is delivered as a module: a self-contained unit that a host, such as a browser or a standalone runtime, loads and runs. A module is built from several kinds of entity. These are the main ones:

- **Functions** are the units of code, each with a typed signature.
- **Memories** are just growable arrays of bytes.
- **Globals** hold a single scalar value and have a declared mutability.
- **Tables** hold references and are used mainly for indirect calls.
- **Tags** identify typed events that control flow can raise.

A module can define each of these itself or import it from the host, and it chooses which of them to export [1].

This thesis shows modules in WAT, the text form of WebAssembly. Parentheses group each part of a module, and a name that starts with `$` labels an entity. Nested instructions such as `(call $log (i32.const 42))` are written this way for readability. In reality they are a sequence: `42` is pushed first, then `$log` is called.

Consider a small module:

```wat
(module
  (import "host" "log" (func $log (param i32)))
  (func $run (call $log (i32.const 42)))
  (export "run" (func $run)))
```

1. Import the function `"log"` from the `"host"` namespace and name it `$log`. It takes one `i32`.
2. Define function `$run`, which calls `$log` with the constant `42`.
3. Export `$run` under the name `"run"`.

#### The sandbox

This module cannot log anything by itself. The host must provide `host.log` when it instantiates the module. This is the core of WebAssembly's sandbox: a module can only reach what it contains and what the host hands to it [2]. Three rules enforce this:

1. **Memory is closed.** Code can access only its own memories, globals and tables, and an access outside a memory traps.
2. **Control flow is structured.** A branch can only jump to an enclosing block, an indirect call is checked against the expected function type, and the call stack lives outside the module's memory.
3. **Outside access goes through imports.** Files, the network and the clock exist for a module only if the host provides them as imported functions.

The sandbox has two limits. It protects the host from the module, not the module from itself: memory is untyped bytes, so a bug can still corrupt the module's own data. And an imported function can grant a great deal of power. WASI, for example, is a standard set of such functions for files and system services, and it is not part of core WebAssembly.

These entities are the surface of the platform: the things a developer might want to name in a program. The rest of this chapter asks how much of that surface each programming language lets a developer name.

[1] WebAssembly Core Specification, Modules. https://webassembly.github.io/spec/core/syntax/modules.html
[2] WebAssembly Core Specification, Introduction. https://webassembly.github.io/spec/core/intro/introduction.html
