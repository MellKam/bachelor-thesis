#import "../../template.typ": booktable, muted, todo

= Items: the Platform's Entities as Types <ch:items>

@ch:background showed that the entities of a WebAssembly module (memories, globals, tables and tags) are the part of the platform that languages expose least (@fig:entities). This chapter describes how WX represents them. The idea is simple: every entity is an *item* of the language, every item has its own type, and a trait that the compiler implements says what the item can do. The next three chapters reuse this idea for values, calls and instructions.

== Reading WX <sec:reading-wx>

WX syntax is based on Rust, and its keywords for entities come from the WebAssembly text format. @lst:wx-tour shows a small, complete module. It type-checks with the current compiler.

#figure(
  ```wx
  memory heap: u32;                   // a linear memory with 32-bit addresses
  global mut count: u32 = 0;          // a mutable global

  import "env" as env {
      func log(value: u32);           // a function the host provides
  }

  func sum(xs: heap::&[u32]) -> u32 {
      local mut total: u32 = 0;
      local mut i: u32 = 0;
      loop {
          if i == xs.len() { break };
          total += xs[i];
          i += 1;
      };
      count.set(count.get() + 1);
      env::log(total);
      total
  }

  export { heap as "memory", sum }
  ```,
  caption: [A small WX module.],
) <lst:wx-tour>

A few things in this listing differ from Rust and are used in every chapter:

- `func`, `global` and `memory` declare the WebAssembly entity of the same name. `local` declares a local variable.
- Every pointer type names the memory it points into: `heap::&u32` is a shared pointer to a `u32` in `heap`, and `heap::*u32` is an exclusive one. `heap::&[u32]` is a slice. The compiler rejects a write through a `&` pointer, but the full ownership rules behind the two are designed and not checked yet.
- `p.*` reads or writes the value a pointer points at, and `xs[i]` an element of a slice (@sec:memory-access).
- A bound can fix an associated type: `M: Memory where { Size = u32 }` means "any memory with 32-bit addresses". This is Rust's `Iterator<Item = u8>`, written differently.
- A literal such as `0` has no default type. Its type always comes from the context, here from `u32` in the declaration.

== Entities are numbers in WebAssembly <sec:identity-shape>

Inside a WebAssembly module, an entity is a number. A function is referred to by its index in the function index space, and imported functions come before defined ones @wasm-spec-modules. So adding an import changes the index of every defined function:

```wat
(module
  (import "env" "log" (func (param i32)))   ;; function 0
  (func (result i32) i32.const 42)          ;; function 1, was 0 before the import
  (export "run" (func 1)))
```

The text format allows names such as `$run` instead of numbers, and replaces them with indices when the module is encoded. Memories, tables, globals and tags work the same way, each with its own index space. A name like `$run` is still only a name for a number.

A language that lets a program use these entities has to decide what type they have. There are two simple answers, and both have a problem.

The first answer is to use the index itself. Zig's `@wasmMemoryGrow` builtin takes the memory as a `u32` index @zig-wasm-builtins. This is fine for a low-level builtin, but then any integer can be used as a memory, and the type system cannot tell a memory index from a loop counter. It also cannot know whether the memory uses 32-bit or 64-bit addresses, because the integer says nothing about it.

The second answer is to describe only what the entity looks like: a function by its signature, a memory by its address type. Then two functions with the same signature have the same type, and so do two memories with 32-bit addresses. A pointer into one memory could be used as a pointer into the other, and the compiler could not see the mistake.

So a program needs both: what kind of entity it is and which one (its *identity*), and what can be done with it (its *shape*). @tbl:kinds lists the shape of each kind. I found this distinction only after several versions of the design; it was not the starting point.

#figure(
  booktable(
    columns: (auto, 1fr, auto),
    align: (left, left, left),
    table.header([Kind], [Shape: what a use is checked against], [In WX]),
    table.hline(stroke: 0.5pt),
    [Function], [parameter and result types], [implemented],
    [Global], [value type, mutability], [implemented],
    [Memory], [address type (32 or 64 bits)], [implemented],
    [Table], [reference type, address type], [designed],
    [Tag], [payload types], [designed],
  ),
  caption: [The kinds of WebAssembly entity and their shape.],
) <tbl:kinds>

This gives three goals for the design:

- *Stable references.* Adding an import or a definition never changes how existing code refers to an entity.
- *Every kind can cross the module boundary.* Every kind of entity can be defined, imported and exported.
- *Distinct identities without numbers.* Two entities of the same kind are different to the type system, and a program never uses an entity's index as an integer.

== Every item is a type <sec:items-as-types>

In WX, every entity is declared as an item, and every item has its own type. The declaration `memory heap: u32;` creates an item `heap` and a type that is also called `heap`. This type is *zero-sized*: its values take no space at run time. It has exactly one value, which is also written `heap`. So the name `heap` can be used in three places:

- *As a type:* in a pointer type `heap::&u32`, or as a generic argument, as in `size_of::<T, heap>()`.
- *As a value:* `count.get()` calls a method on the global `count`.
- *As a namespace:* `heap::PAGE_SIZE` is a constant of the memory.

The identity of an item is its type. The compiler knows it everywhere the item is used, and turns it into a WebAssembly index only at code generation, after it knows all imports and definitions. Because the value is zero-sized, passing an item to a function costs nothing at run time: the instruction receives the index as an immediate, not as an operand.

Rust has a similar idea. Every Rust function has its own zero-sized type, so two functions with the same signature have different types. But a Rust program cannot write that type, and the type is lost when the function is converted to a function pointer. In WX, the type of every item can be written in the source, and every kind of entity has one, not only functions.

*Status.* In the current type checker, items are fully supported as types. Functions and globals can also be used as values. Using a memory as a value, as in `memory_size(heap)`, is reported as not supported yet (E2114).

== Pointers carry their memory <sec:pointers-memory>

With the multi-memory extension, a module can have several linear memories @wasm-multi-memory. Each memory has its own addresses, and every load and store instruction names its memory as an immediate. A pointer type that only says what it points to, like `*u8`, is not enough: two pointers of that type can point into different memories, and the compiler must know which memory to use for each load.

One option is a *fat pointer*, which stores the memory index next to the address at run time. This costs space for every pointer, and because a load names its memory as an immediate, a memory index known only at run time would need a branch over all memories at every access.

WX puts the memory in the pointer's type instead. `heap::*u8` is a pointer to a byte in `heap`. A pointer into another memory has a different type, and using it in the wrong place is an ordinary type error (@fig:cross-memory). The compiler knows the memory of every load and store from the type, so nothing is stored at run time.

#figure(
  kind: raw,
  supplement: [Listing],
  text(size: 0.8em)[
  ```text
  // memory heap: u32;
  // memory io: u32;
  // func read(p: heap::&u32) -> u32 { p.* }

  error[E2001]: type mismatch
       ┌─ /main.wx:2381:39
       │
  2381 │ func wrong(p: io::&u32) -> u32 { read(p) }
       │                                       ^ expected `heap::&u32`, found `io::&u32`
  ```
  ],
  caption: [A pointer into one memory used where a pointer into another is expected. The test appends its source to the standard library, hence the line number. Compiler at `186ba25`, branch `tir-refactor`, 2026-10-30.],
) <fig:cross-memory>

There is no default memory. A pointer type without a memory is an error, even in a module with only one memory, and the compiler's message states the rule (@fig:untagged-pointer).

#figure(
  kind: raw,
  supplement: [Listing],
  text(size: 0.8em)[
  ```text
  error[E2038]: a pointer type must name its memory
       ┌─ /main.wx:2378:14
       │
  2378 │ func read(p: *u32) -> u32 { p.* }
       │              ^^^^ no memory written here
       │
       = write the memory before the sigil: `heap::*T`, or a memory parameter `Mem::*T`
  ```
  ],
  caption: [A pointer type without a memory. The test appends its source to the standard library, hence the line numbers. Compiler at `186ba25`, branch `tir-refactor`, 2026-10-30.],
) <fig:untagged-pointer>

Code that works with any memory uses a type parameter for it: `M::*u8` is a pointer into whichever memory `M` is. For this, `M` must be known to be a memory, and that needs a trait.

== Traits describe what an item can do <sec:why-traits>

For every declared memory, the compiler implements the `Memory` trait from the standard library. No impl is written in the source. For `memory heap: u32;` the compiler behaves as if this impl existed:

```wx
impl Memory for heap {
    type Size = u32;
}
```

The associated type `Size` is the memory's address type: `u32` for a 32-bit memory, `u64` for a 64-bit one (`memory big: u64;`). The trait is shortened here:

```wx
pub trait Memory {
    type Size: PointerSize;
    const PAGE_SIZE: Self::Size = 65536;

    func grow(self: Self, delta: Self::Size) -> Self::Size::Signed { .. }
    func size_pages(self: Self) -> Self::Size { .. }
}
```

Generic code can now work with any memory and still use the right address type. A function that takes `M::*u8` and a length of type `M::Size` works on a 32-bit and a 64-bit memory, and the compiler checks it once, for every possible `M`. So generic code cannot silently assume a 32-bit memory. In @fig:generic-memory, the length is a `u32`, which is correct for `heap` but not for every `M`, and the compiler rejects the function before it is ever called with a 64-bit memory.

#figure(
  kind: raw,
  supplement: [Listing],
  text(size: 0.8em)[
  ```text
  error[E2112]: type mismatch resolving `<M as Memory>::Size == u32`
       ┌─ /main.wx:2379:63
       │
  2079 │     DstMem: Memory where { Size = Size },
       │                                   ---- required by this equality in `memory_copy`
       ·
  2379 │ func copy<M: Memory>(dst: M::*u8, src: heap::&u8, len: u32) { memory_copy(dst, src, len) }
       │                                                               ^^^^^^^^^^^ expected `u32`, found `<M as Memory>::Size`
  ```
  ],
  caption: [Generic code that assumes a 32-bit memory. `memory_copy` is shown in @sec:intrinsic-entities. The test appends its source to the standard library, hence the line numbers. Compiler at `186ba25`, branch `tir-refactor`, 2026-10-30.],
) <fig:generic-memory>

 A program cannot implement `Memory` for its own types, because its methods need a real WebAssembly memory behind them.

Globals work the same way. For `global mut count: u32 = 0;` the compiler implements `Global` with `type Value = u32`, which gives the method `get`, and `GlobalMut`, which gives `set`. A global declared without `mut` gets only `Global`, so a program cannot write to it: the `set` method does not exist for it. Which values a global may hold is the subject of @ch:stack-values.

=== Typesets <sec:typesets>

`Memory::Size` must be `u32` or `u64` and nothing else. An ordinary trait bound cannot say this. If `PointerSize` were a normal trait, any code could later implement it for another type, such as `u8`, and the bound would accept it. WX adds a *typeset*: a closed set of types, listed in its declaration (@fig:typeset-vs-trait).

#figure(
  kind: raw,
  supplement: [Listing],
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1.2em,
    row-gutter: 0.6em,
    [*Closed: `typeset`*], [*Open: `trait`*],
    [
      ```wx
      typeset PointerSize { u32, u64 }

      impl PointerSize for u8 {}
      // error[E2031]: expected trait,
      // found typeset
      ```
    ],
    [
      ```wx
      trait PointerSize {}
      impl PointerSize for u32 {}
      impl PointerSize for u64 {}

      impl PointerSize for u8 {} // accepted
      ```
    ],
  ),
  caption: [The same third `impl`, rejected by a typeset and accepted by an ordinary trait.],
) <fig:typeset-vs-trait>

A typeset is used in bounds like a trait, but it cannot be implemented: its members are listed only in its declaration. It can also require traits, so every member of `PointerSize` also has addition, comparison and the other operations that generic code needs on an address.

== Imports and exports <sec:items-imports>

An imported entity is the same kind of item as a defined one. Only its origin is different. An import block names the host module and declares what it expects from it:

```wx
import "env" as env {
    func log(value: u32);
    global mut total: u32;
    memory shared: u32;
}
```

An imported function has no body, and an imported global has no initial value. The items are used through the block's name: `env::log`, `env::total`, `env::shared`. They get the same types and traits as defined items, so an imported memory is a `Memory` and an imported `global mut` is a `GlobalMut`.

A package that is compiled to a module has one export block, which lists the items the host can use, optionally under another name:

```wx
export { sum, heap as "memory" }
```

The compiler assigns all indices at code generation, imports first. A program never writes or computes an index, so adding an import never changes existing code.

== Tables and tags: designed, not implemented <sec:items-kinds>

Tables and tags are not implemented. The design follows the same pattern. A table would be declared like a memory, and the compiler would implement a trait that gives its operations (`table.get`, `table.set`, `table.grow`). A handle to a table slot would carry its table in its type, as a pointer carries its memory. A tag would be declared like a struct with a payload, and the compiler would implement a `Tag` trait for it. These designs are kept short here because none of them can be tested yet. #todo[Expand only if tables or tags are implemented before submission; source: `notes/wx-tables-references-design.md`.]

== One mechanism <sec:items-summary>

Every part of this chapter uses the same mechanism: a short declaration creates an item with its own zero-sized type, and the compiler implements a trait for that type (@tbl:items-mechanism). The trait gives the item's shape as associated types, and its operations as methods. Nothing in the type checker is specific to memories or globals except the code that writes these impls.

#figure(
  booktable(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    table.header([Declaration], [Type], [Impl written by the compiler]),
    table.hline(stroke: 0.5pt),
    [`memory heap: u32;`], [`heap`], [`Memory` with `Size = u32`],
    [`global mut count: u32 = 0;`], [`count`], [`Global` with `Value = u32`, and `GlobalMut`],
    [`func add(a: i32, b: i32) -> i32`], [`add`], [`Call` with `Args = (i32, i32)`, `Result = i32` (@ch:calls)],
  ),
  caption: [Declarations, their item types and the traits the compiler implements for them.],
) <tbl:items-mechanism>

The next chapters use the same mechanism for things that are not declarations. @ch:stack-values describes a trait that the compiler implements for every type, and @ch:calls a trait it implements for every function.
