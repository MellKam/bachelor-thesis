#import "../../template.typ": todo, booktable, muted

= Items: Representing the Platform's Entities <ch:items>

// Working outline: plan.md, section 3 (reordered 2026-10-09: problem first, syntax last). Storytelling rule: show the
// problem that was seen and how it was solved, so the reader is not asked to trust the design. Introduce each piece
// of background when the story first needs it; wx syntax appears as small glossed fragments and is assembled in one
// place at the end. Chapter 2 hands over five design questions (@sec:synthesis); this chapter answers the first two
// and part of the fifth. Design details for tables, tags and references: notes/wx-tables-references-design.md in the
// compiler repository. Status of this file: stub. Every section below names what it will say and where the material is.

#todo[Stub. One idea for the whole chapter: every WebAssembly entity becomes a language item. An item's identity is a unique zero-sized type and its shape is what the compiler implements for that type. The chapter ends on the type-level guarantees only; "no raw indexes" is completed in the next chapter, where intrinsics are introduced. State this in a forward pointer at the end. Tables, tags, host types and references are designed and not implemented: say so once per section.]

== Entities, identity and shape <sec:identity-shape>

#todo[The problem, stated precisely, with WAT the reader already knows from Chapter 2. Table of kinds: function, table, memory, global, tag, each with its identity (kind and index) and its shape (signature; reference type, limits and index type; limits, shared flag and index type; value type and mutability; signature). Each kind has its own index space and imports take the first indices, so a final index is a late layout decision. Languages give shape but identity only to functions and globals (back-reference to the Chapter 2 rows). Functions are the one kind whose shape is also checked at run time. Say that the identity and shape vocabulary was found in hindsight. Mention nominal versus structural once. Requirements: definable, nameable, usable; imports and exports alike for every kind; no raw indexes; no cross-memory pointers.]

== Approaches considered <sec:approaches>

#todo[Memory as an integer (any integer behaves as a memory). Memory as a runtime value or built-in functions (the index should be a compile-time immediate and never be carried in a variable). Memory as an item that is a type. The first two in neutral pseudocode, labelled as such. Honest chronology: memory came first and the other kinds were checked against the same model afterwards.]

== Items as unique zero-sized types <sec:items-as-types>

#todo[Definition in the style of `struct foo;`, so the compiler reuses the struct mental model. Internally one type per declaration, carrying an index. Differences from a Rust unit struct: it carries a compile-time index (an index into the per-kind vector, turned into the real Wasm index only at codegen), and the item is also a value of its type that can be passed around but not constructed from nothing. Scope the claim to the identity type: a tag carries a payload.]

== Names, paths and scopes <sec:items-paths>

#todo[`heap`, `heap::PAGE_SIZE`, `heap::*u8`: an item is a type, a value and a namespace at once. Visibility.]

== Pointers carry their memory <sec:pointers-memory>

#todo[`M::*u8`. A pointer from one memory used as another is a type error. This needs a bound that says "M is a memory". Include a real compiler diagnostic, with the commit and date it was taken from.]

== Why traits <sec:why-traits>

#todo[`Memory` and `Global`/`GlobalMut`, implemented by the compiler for every declaration. Associated types `Size` and `Value`; 64-bit memory comes for free; generic code over any memory. Dated syntax evolution: `memory heap: Memory where { Size = u32 };` (an arbitrary bound expression at parse level, hard to parse and validate) became `memory heap: u32;`. The table that sorts a shape piece by mechanism: associated type, declaration modifier that selects a trait, attribute. Do not quote `examples/` for syntax until it is updated.]

== The other kinds <sec:items-kinds>

#todo[Designed and not implemented; say so. Tags: a struct plus a result type, `Exception` as an explicit opt-in, not zero-sized. Tables: `table[func]` and `table[extern]`, the kind is compiler-internal and picks a trait, one table holds any funcref or externref. Host types: `type Node: extern;` with a required kind bound; no nominal function types. Handles and references as two layers, parallel to memory pointers and values; why Wasm has both. Where the operations live is for the next chapter (`h.*` is `table.get`, `as_ref()` is `ref.func`). Include the design story beats from plan.md as the reasoning.]

== Imports and exports <sec:items-imports>

#todo[Principle: an imported item is the same kind of item as a defined one, only its origin differs; in the compiler, declared and imported memories and globals share one signature routine. The import block (functions by signature; globals and memories reuse the item declaration), the export block (unique per package, at the binary root, never in a library; optional rename), and how indexes are assigned (imports first, at codegen). `INDEX` as a read-only debug constant that no intrinsic accepts. Open: why a separate export block instead of marking each item. Answers Chapter 2 design question 5 together with the WASI examples later.]

== The design assembled <sec:items-assembled>

#todo[One complete example in the final syntax: memory, global, table, tag, an import block with a host type, an export block. Status table: item kind by define, name, use, import, export, marked implemented or designed.]

== What this gives and what it does not <sec:items-summary>

#todo[The type-level guarantees: an item cannot be used as an integer, and a pointer cannot cross memories. Links to design questions 1, 2 and 5 of @sec:synthesis. What is not claimed: ownership is designed and not enforced, bounds still trap at run time, and a table slot can still be null or out of range. Forward pointer to the next chapter for intrinsics.]
