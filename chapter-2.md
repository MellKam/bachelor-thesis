# Chapter 2 — WebAssembly background and related work (working sketch)

**Purpose.** Give the reader just enough of WebAssembly's execution and module model to
understand the design choices in the later chapters. The thread running through this chapter
is: *what does Wasm represent explicitly, and what does a source language have to add?*
Chapter 1 already motivates the thesis; this chapter should establish the technical facts
and the comparison baseline, without introducing wx's detailed syntax yet.

### 2.1 WebAssembly as a language target

Introduce Wasm as a portable, validated instruction format, independent of a particular
host. Explain the distinction between the binary module (`.wasm`), its readable text form
(WAT), and the browser or other embedder that instantiates it. A module defines or imports
functions, memories, tables, globals, and tags, and chooses what to export. These categories
have separate index spaces. Mention tables only enough to explain indirect calls; they are
not a main subject of this thesis. The [core specification's module description](https://webassembly.github.io/spec/core/syntax/modules.html)
is the primary source.

Use one small WAT example throughout the section:

```wat
(module
  (import "host" "log" (func $log (param i32)))
  (func (export "run")
    i32.const 42
    call $log))
```

Walk through the explicit import, typed parameter, operand stack, and export. The module
cannot log by itself: the embedder must provide `host.log` at instantiation. This makes the
sandbox claim from Chapter 1 concrete. Clarify that Wasm's lack of ambient host access is a
property of the *core module model*; imported functions can still grant powerful authority.
WASI is one possible host interface, not part of core Wasm. [Core specification: security and
embedding](https://webassembly.github.io/spec/core/intro/introduction.html).

### 2.2 The execution model features that shape a source language

Cover these in roughly this order, each with a short explanation and one sentence saying
why it matters to language design:

1. **Typed operand stack and validation.** `i32.const` pushes a value; `i32.add` consumes two
   `i32`s and produces one. Function and block signatures constrain the stack. A validator
   can check an instruction stream in one pass. This motivates explicit value widths and
   block results later; it is not a claim that source-language type checking is trivial.
   [Instruction typing](https://webassembly.github.io/spec/core/valid/instructions.html) ·
   [validation algorithm](https://webassembly.github.io/spec/core/appendix/algorithm.html).
2. **Structured control flow.** `block`, `loop`, `if`, and branch labels delimit where a
   branch can go; a block may return values. Show one tiny value-producing `block` and its
   source-level analogue. This prepares the reader for wx's block expressions and labeled
   `break`/`continue`. [Instruction syntax](https://webassembly.github.io/spec/core/syntax/instructions.html).
3. **Linear memory and references.** Linear memory is addressable bytes, with bounds-checked
   loads and stores; Wasm itself does not assign a source-language type, lifetime, or
   ownership rule to an address. Distinguish a byte address from a Wasm reference value.
   Explain that a module can import or export a memory, and that it can have multiple
   distinct memories. This is the essential setup for wx's memory-aware pointer types.
   [Memories and modules](https://webassembly.github.io/spec/core/syntax/modules.html).
4. **Globals and tables.** A global holds one Wasm value and has declared mutability; a
   table holds references used, among other things, for indirect calls. Give globals more
   space because wx later exposes them directly; keep tables to a paragraph.
   [Wasm types](https://webassembly.github.io/spec/core/syntax/types.html).
5. **Imports and exports as the capability boundary.** Return to the WAT example to make
   clear why calls across this boundary matter to the proposed effect system. Do not imply
   that *every* effect crosses it: traps and memory writes happen inside a module too.

### 2.3 Extensions relevant to the thesis

Describe *only* the semantics needed for later chapters, preferably in a compact table:

| Feature | Fact to explain now | Later connection |
| --- | --- | --- |
| Multiple memories | Memory operations can select a memory; memories are separate indexed byte stores. | Why memory identity can be visible in a type. |
| Memory64 | A memory can use `i64` rather than `i32` addresses. | Why pointer/address width should follow the chosen memory. |
| GC | Wasm adds typed, managed `struct` and `array` references alongside linear memory. | A future wx design question; GC references are not literally another linear memory. |
| Exception handling | Tags identify typed exceptions; `throw` raises one and `try_table` installs catches. | Context for the later, explicitly unimplemented tag/effect design. |
| Stack switching | A separate proposal adds continuations and control tags. | Future work only; one paragraph of motivation is enough here. |

The first four appear in the [finished proposals list](https://github.com/WebAssembly/proposals/blob/main/finished-proposals.md)
and in the current core specification. Stack switching remains a
[separate proposal](https://github.com/WebAssembly/stack-switching/blob/main/proposals/stack-switching/Explainer.md).
Use **`try_table`** for the current exception-handling instruction; older `try`/`catch`
material belongs to the legacy form. A brief sentence can acknowledge other features
(SIMD, threads, tail calls) and explain why the thesis does not analyze them. Avoid a long
proposal chronology or a browser-support matrix: neither is needed for the design argument.

### 2.4 Related languages: compare the same problem in each

Frame these as different, reasonable answers to *where memory management and Wasm-specific
capabilities sit in the source language*. Compare documented language/runtime behavior,
not simply whether each compiler can produce a Wasm file.

| Language | Useful example or point of comparison | Question to ask in the thesis |
| --- | --- | --- |
| **AssemblyScript** | TypeScript-like source language with a runtime that manages objects in linear memory; runtime variants expose different collection behavior. [Runtime documentation](https://www.assemblyscript.org/runtime.html). | How much of the memory model does a typical program see? Which choices require changing runtime configuration or using low-level APIs? |
| **Zig** | Systems-language model with explicit allocators, Wasm targets, host imports/exports, and low-level `@wasmMemorySize`/`@wasmMemoryGrow` builtins that accept a memory index. [Current language reference](https://ziglang.org/documentation/master/#WebAssembly) · [builtins](https://ziglang.org/documentation/master/#wasmMemorySize). | Does a pointer's type identify its Wasm memory, or is the memory index mainly an operation-level concern? Avoid claiming Zig has no multiple-memory support. |
| **Grain** | Wasm-first language with a linked runtime/collector and a configurable heap. [Runtime account](https://grain-lang.org/blog/2021/04/29/new-release-grain-v0.3.0-barley/) · [CLI options](https://grain-lang.org/docs/tooling/grain_cli). | Which Wasm details are intentionally hidden behind managed values? |
| **MoonBit** | Distinct Wasm and Wasm GC backends: the latter represents data with GC references rather than using linear memory by default. [FFI and backend documentation](https://docs.moonbitlang.com/en/stable/language/ffi.html). | How does selecting a backend compare with expressing more than one storage model inside a language design? |

For a fair comparison, apply the same four lenses to each: **storage identity in types**,
**memory-management policy**, **host boundary**, and **access to evolving Wasm features**.
One small code example per language would be stronger than a long catalog of features:
for example, allocation or memory growth plus a host import. Verify each snippet against
a pinned release before it enters the final thesis. State only what the examples and
documentation establish; absence of a documented feature is not proof that it is impossible.

### 2.5 Transition to the wx design

End with three questions that the next chapters answer: Can a pointer identify *which*
memory it addresses? Can memory and global identities participate in ordinary generic
constraints? Can the module boundary and exception tags remain visible while the language
provides safer operations? This gives the comparison a payoff without previewing the exact
wx declarations or repeating the later design argument.

**Suggested final-chapter visuals:** the WAT import/export example above, a small diagram of
two indexed linear memories beside a distinct GC heap, and the four-language comparison
table. Keep the prose focused on the facts each visual helps explain.
