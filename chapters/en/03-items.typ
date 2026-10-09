#import "../../template.typ": todo, booktable, muted

= Items: Representing the Platform's Entities <ch:items>

// Working outline: plan.md, section 3. Storytelling rule: show the problem that was seen and how it was solved, so
// the reader is not asked to trust the design. Introduce each piece of background when the story first needs it.
// Chapter 2 hands over five design questions (@sec:synthesis); this chapter answers the first two and part of the fifth.
// Status of this file: stub. Every section below names what it will say and where the material is.

#todo[Stub. One idea for the whole chapter: every WebAssembly entity (function, global, memory, later table and tag) becomes a language item, and an item is a unique zero-sized type. The chapter ends on the type-level guarantees only; "no raw indexes" is completed in the next chapter, where intrinsics are introduced. State this in a forward pointer at the end.]

== Reading wx <sec:reading-wx>

#todo[Half-page syntax primer for readers who do not know Rust. Only what the following sections use.]

== Items of a module <sec:items-module>

#todo[What defining, naming and using an entity means, and why a marker or build flag is not enough (back-reference to Chapter 2: memory limits are a linker flag in most languages). Functions and globals first, with the TypeScript-like mental model. Defined here: item, definition, name, use.]

== The problem with memories <sec:memory-problem>

#todo[A memory is only an index in WebAssembly. Open with memory as the case that forced the design; say honestly that the other kinds were checked against the same model afterwards. Rejected: an integer (any integer then behaves as a memory) and a runtime value or built-in function (the index should be a compile-time immediate and never be carried in a variable).]

== Items as unique zero-sized types <sec:items-as-types>

#todo[Definition in the style of `struct foo;`, so the compiler reuses the struct mental model. Internally one type per kind, carrying an index. Differences from a Rust unit struct: it carries a compile-time index (an index into the per-kind vector, turned into the real Wasm index only at codegen), and the item is also a value of its type that can be passed around but not constructed from nothing.]

== Names, paths and scopes <sec:items-paths>

#todo[`heap`, `heap::PAGE_SIZE`, `heap::*u8`: an item is a type, a value and a namespace at once. Visibility.]

== Pointers carry their memory <sec:pointers-memory>

#todo[`M::*u8`. A pointer from one memory used as another is a type error. This needs a bound that says "M is a memory". Include a real compiler diagnostic, with the commit and date it was taken from.]

== Why traits <sec:why-traits>

#todo[`Memory` and `Global`/`GlobalMut`, implemented by the compiler for every declaration. Associated types `Size` and `Value`; 64-bit memory comes for free; generic code over any memory. Dated syntax evolution: `memory heap: Memory where { Size = u32 };` (an arbitrary bound expression at parse level, hard to parse and validate) became `memory heap: u32;`. A more verbose `memory heap where { Size = u32 }` may follow for several associated types and is not implemented. Do not quote `examples/` for syntax until it is updated.]

== Declaring each kind <sec:items-kinds>

#todo[Function; global (mutability, constant-expression initialisers only with the two designs that were scoped back, one scalar per global); memory (`#[memory_limits(min_pages, max_pages)]`); table and tag as designed items. Include the status table: item kind by define, name, use, import, export, marked implemented or designed.]

== Imports and exports <sec:items-imports>

#todo[Principle: an imported item is the same kind of item as a defined one, only its origin differs. The import block (functions by signature; globals and memories reuse the item declaration), the export block (unique per package, at the binary root, never in a library; optional rename), and how indexes are assigned (imports first, at codegen). `INDEX` as a read-only debug constant that no intrinsic accepts. Open: why a separate export block instead of marking each item. Answers Chapter 2 design question 5 together with the WASI examples later.]

== What this gives and what it does not <sec:items-summary>

#todo[The type-level guarantees: an item cannot be used as an integer, and a pointer cannot cross memories. Links to design questions 1 and 2 of @sec:synthesis. What is not claimed: ownership is designed and not enforced, and bounds still trap at run time. Forward pointer to the next chapter for intrinsics.]
