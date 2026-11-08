#import "../../template.typ": booktable, layout, muted, todo
#import "../../bibliography.typ": fnote

= Items: the Platform's Entities as Types <ch:items>

@ch:background identified gaps in how languages expose module entities such as memories, globals, tables and tags (@fig:matrix). WX represents each entity as an *item* with a distinct type. Compiler-provided trait implementations describe the operations available on that item. The next three chapters develop the related mechanisms for values, calls and instructions.

== Reading WX <sec:reading-wx>

WX syntax is based on Rust, and its keywords for entities come from the WebAssembly text format. @lst:wx-tour shows a small, complete module. It type-checks with the current compiler.

#figure(
  ```wx
  import "host" as host {
      global step: i32;
      func log(value: i32);
  }

  global mut count: i32 = 0;

  func increment() {
      local next = count.get() + host::step.get();
      count.set(next);
      host::log(next);
  }

  func decrement() {
      local next = count.get() - host::step.get();
      count.set(next);
      host::log(next);
  }

  export { count, increment, decrement }
  ```,
  caption: [A small WX module.],
) <lst:wx-tour>

When the module is instantiated, the host supplies the global `step` and an implementation of `log`. Calling `increment` or `decrement` changes the counter by that step and logs its new value. The counter is also exported, so the host can read or update it directly. The listing introduces a few basic constructs:

- `global mut` declares a mutable WebAssembly global. Its value persists between calls, and `get` and `set` read and update it.
- `func` declares a function, and `local` declares a variable within it. Each call computes a new `next`, whose type is inferred as `i32`. It needs no `mut` because it is never reassigned.
- `import` declares entities supplied by the host. In `import "host" as host`, the string names the external import namespace, and the name after `as` is used to access its entities in WX. The imported global has no initializer; its value comes from the host. Without `mut`, `step` can be read but not updated by the module.
- `export` makes globals and functions available to the host. The exported `count` is the same global that the two functions update.

Globals are accessed through `get` and `set` to distinguish access to module state from ordinary local computation. The traits behind these methods are explained in @sec:global-access.

== Entity references are indices in WebAssembly <sec:identity-shape>

WebAssembly instructions refer to module entities by indices in separate index spaces. In the function index space, imported functions come before defined ones #fnote("wasm-spec-modules"). Adding a function import therefore changes the index of every defined function:

```wat
(module
  (import "env" "log" (func (param i32)))   ;; function 0
  (func (result i32) i32.const 42)          ;; function 1, was 0 before the import
  (export "run" (func 1)))
```

The text format allows names such as `$run` instead of numbers, and replaces them with indices when the module is encoded. Memories, tables, globals and tags work the same way, each with its own index space. A name like `$run` is still only a name for a number.

A language that lets a program use these entities has to decide what type they have. There are two simple answers, and both have a problem.

The first answer is to use the index itself. Zig's `@wasmMemoryGrow` builtin takes the memory as a `u32` index #fnote("zig-wasm-builtins"). This is fine for a low-level builtin, but then the argument has a plain numeric type, so its type alone does not tell a memory index from a loop counter, and the validity of the value has to be checked separately. It also cannot know whether the memory uses 32-bit or 64-bit addresses, because the integer says nothing about it.

The second answer is to describe only what the entity looks like: a function by its signature, a memory by its address type. Then two functions with the same signature have the same type, and so do two memories with 32-bit addresses. A pointer into one memory could be used as a pointer into the other, and the compiler could not see the mistake.

So a program needs both: what kind of entity it is and which one (its *identity*), and what can be done with it (its *shape*). @tbl:kinds lists the shape of each kind. This distinction was found only after several versions of the design; it was not the starting point.

#figure(
  booktable(
    columns: (auto, 1fr, auto),
    align: (left, left, left),
    table.header([Kind], [Shape: what a use is checked against], [In WX]),
    table.hline(stroke: 0.5pt),
    [Function],
    [parameter and result types],
    [implemented],
    [Global],
    [value type, mutability],
    [implemented],
    [Memory],
    [address type (32 or 64 bits)],
    [implemented],
    [Table],
    [reference type, address type],
    [designed],
    [Tag],
    [payload types],
    [designed],
  ),
  caption: [The kinds of WebAssembly entity and their shape.],
) <tbl:kinds>

This gives three goals for the design:

- *Stable references.* Adding an import or a definition never changes how existing code refers to an entity.
- *Every kind can cross the module boundary.* Every kind of entity can be defined, imported and exported.
- *Distinct identities without numbers.* Two entities of the same kind are different to the type system, and a program never uses an entity's index as an integer.

== Every item is a type <sec:items-as-types>

In WX, every entity is declared as an item, and every item has its own type. The declaration `memory heap: u32;` creates an item `heap` and a type that is also called `heap`. This type is *zero-sized*: its values take no space at run time. It has exactly one value, which is also written `heap`. Item names can be used in three roles:

- *As a type:* in a pointer type `heap::&u32`, or as a generic argument, as in `size_of::<T, heap>()`.
- *As a value:* `count.get()` calls a method on the global `count`.
- *As a namespace:* `heap::PAGE_SIZE` is a constant of the memory.

The identity of an item is its type. The compiler knows it everywhere the item is used, and turns it into a WebAssembly index only at code generation, after it knows all imports and definitions. Because the value is zero-sized, passing an item to a function costs nothing at run time: the instruction receives the index as an immediate, not as an operand.

Rust has a similar idea. Every Rust function has its own zero-sized type, so two functions with the same signature have different types. But a Rust program cannot write that type, and the type is lost when the function is converted to a function pointer. In WX, the type of every item can be written in the source, and every kind of entity has one, not only functions.

== Pointers carry their memory <sec:pointers-memory>

A linear memory is a growable array of bytes, measured in 64 KiB pages #fnote("wasm-spec-modules"). The `u32` in `memory heap: u32;` is its address type, not its current size. WX also accepts `memory heap: u64;` for Memory64.

With the multi-memory extension, a module can have several linear memories #fnote("wasm-multi-memory"). Each memory has its own addresses, and every load and store instruction names its memory as an immediate. A pointer type that only says what it points to, like `*u8`, is not enough: two pointers of that type can point into different memories, and the compiler must know which memory to use for each load.

One option is a *fat pointer*, which stores the memory index next to the address at run time. This costs space for every pointer, and because a load names its memory as an immediate, a memory index known only at run time would need a branch over all memories at every access.

WX puts the memory in the pointer's type instead. `heap::*u8` is a pointer to a byte in `heap`. A pointer into another memory has a different type, and using it in the wrong place is an ordinary type error (@fig:cross-memory). The compiler knows the memory of every load and store from the type, so nothing is stored at run time.

#figure(
  ```wx
  memory heap: u32;
  memory io: u32;

  func read(p: heap::&u32) -> u32 { p.* }

  func wrong(p: io::&u32) -> u32 {
      read(p)
      //   ^ error[E2001]: type mismatch:
      //     expected `heap::&u32`, found `io::&u32`
  }
  ```,
  caption: [A pointer into one memory used where a pointer into another is expected. The diagnostic is shortened from the compiler's output.],
) <fig:cross-memory>

There is no default memory. A pointer type without a memory is an error, even in a module with only one memory, and the compiler's message states the rule (@fig:untagged-pointer).

#figure(
  ```wx
  memory heap: u32;

  func read(p: *u32) -> u32 { p.* }
  //           ^^^^ error[E2038]: missing memory in pointer type
  //           help: write the memory before the pointer, like `heap::*u32`
  ```,
  caption: [A pointer type without a memory. The diagnostic is the compiler's, reformatted as comments.],
) <fig:untagged-pointer>

A pointer type has three parts (@fig:pointer-anatomy). The middle part, `*` or `&`, is the pointer's *ownership*. A `*` pointer is mutable: the program may read and write through it. A `&` pointer is read-only. They are meant to become an exclusive pointer and a shared reference, but the current compiler does not check aliasing or lifetimes, so today only the right to write tells them apart.

#figure(
  {
    let c-mem = rgb("#1f6fb2")
    let c-ownership = rgb("#b25a1f")
    let c-pointee = rgb("#2a7d4b")
    let part(name, note, color) = stack(
      dir: ttb,
      spacing: 4pt,
      line(length: 100%, stroke: 1.5pt + color),
      align(center, text(weight: "bold", fill: color, name)),
      align(center, text(size: 0.85em, note)),
    )
    stack(
      dir: ttb,
      spacing: 10pt,
      block(width: 100%, text(size: 1.25em, weight: "bold", {
        // Equal flexible space before, between and after the two types.
        for (memory, sigil, pointee) in (("heap", "*", "u8"), ("io", "&", "u32")) {
          h(1fr)
          text(font: layout.mono, fill: c-mem, memory + "::")
          text(font: layout.mono, fill: c-ownership, sigil)
          text(font: layout.mono, fill: c-pointee, pointee)
        }
        h(1fr)
      })),
      grid(
        columns: (1fr, 1fr, 1fr),
        column-gutter: 6pt,
        part("memory", "which memory the address is in", c-mem),
        part("ownership", [`*` mutable, `&` read-only], c-ownership),
        part("pointee", "the type of the value at the address", c-pointee),
      ),
    )
  },
  kind: image,
  supplement: [Figure],
  caption: [The parts of a pointer type, as in `heap::*u8` and `io::&u32`.],
) <fig:pointer-anatomy>

== Where a pointer comes from <sec:pointer-sources>

A pointer type names its memory, but a memory declaration only creates the item `heap`, which holds no bytes that the program can name. The simplest source of pointers is static data. A string literal such as `"hi"` has the type `[u8; 2]`: an array of two bytes that lives in no memory, so it has no address. When a declaration asks for a pointer type, the compiler *places* the bytes in the static data of the memory that the type names, and the value becomes a pointer to them (@lst:literal-placement).

#figure(
  ```wx
  memory heap: u32;
  memory io: u32;

  func demo() {
      local a: heap::&[u8] = "hi";
      local b: io::&[u8] = "hi";
  }
  ```,
  caption: [One literal placed in two memories. The context chooses the memory, so `a` and `b` have different types.],
) <lst:literal-placement>

== Dynamic memory is a convention <sec:dynamic-memory>

Static data is fixed when the program is compiled. A program that needs memory whose size it learns only while running must ask for it. WebAssembly does not do this for the program. The runtime gives a module linear memories, a growable buffer of bytes for each `memory` the module declares, and the language has no built-in way to divide a buffer into blocks. The program makes that decision itself, with an *allocator*: ordinary code that keeps a record of which bytes are free and hands them out on request.

The simplest allocator keeps one number, the first free address, and moves it forward on every request:

```wx
memory heap: u32;

global mut next: u32 = 4; // address 0 means null

func alloc(size: u32) -> heap::*u8 {
    local start = next.get();
    next.set(start + size);
    local p: heap::*u8 = transmute(start);
    p
}
```

This version has no `free` and never grows the buffer. Real allocators reuse freed blocks and grow the memory when it is full, but they make the same kind of decision.

Since the language provides no allocator, allocation is a convention, the same one Zig uses: the program chooses the allocator and passes it to the code that needs memory #fnote("zig-allocators"). The cost is that nothing checks how the program uses the memory. A block can be used after it is freed, freed twice, or reached through two pointers. Preventing this would need some form of linear types to manage such resources, which is outside the scope of this thesis.

== Polymorphism and traits over memories <sec:why-traits>

The allocator above works only for `heap`. Its return type is `heap::*u8`, and `io::*u8` is a different type. A second allocator for `io` would repeat the same logic, and allocators also combine: an arena takes its blocks from a larger allocator. We want to write each allocator once and use it with any memory.

*Polymorphism* means one piece of code that works for many types. A function takes a type parameter, `M`, that stands for "some memory", and the caller fills it in:

```wx
// `M` is chosen by the caller; the body is the one above, with `M` for `heap`.
func alloc<M: Memory>(size: M::Size) -> M::*u8 { .. }
```

Calling it with `heap` gives `heap::*u8`, and calling it with `io` gives `io::*u8`. The compiler checks the body once, against the placeholder, and then makes a separate copy of the function for each memory it is used with.

A placeholder alone is not enough. The body compares and adds addresses, and the compiler cannot assume such operations exist for an arbitrary type. A *trait* states what a type must provide. It is a named set of types and operations that a type can implement, as in Rust's traits and Haskell's type classes #fnote("rust-traits")#super[,]#fnote("haskell-type-classes"). A function written `func f<M: Memory>(..)` accepts only types that implement `Memory`, and its body may use only what `Memory` promises.

The first thing generic code needs to know about a memory is its address type, so `Memory` starts with that. The compiler implements it for every declared memory, so no impl appears in the source. For `memory heap: u32;` the compiler behaves as if this impl existed:

```wx
trait Memory {
    type Size;
}

impl Memory for heap {
    type Size = u32;
}
```

`Size` is an *associated type*: each type that implements `Memory` chooses its own. For `heap` it is `u32`, and for `memory big: u64;` it would be `u64`. Generic code refers to it as `M::Size`, so an allocator can take a length of type `M::Size` and be correct for a 32-bit and a 64-bit memory alike.

=== Typesets <sec:typesets>

So far, `Size` can be any type. But a WebAssembly memory has only two address types, 32 and 64 bits. Generic code should be able to rely on that, for example to add two addresses or compare them, and nothing in `type Size;` guarantees it.

The natural fix is to require `Size` to implement a trait, `PointerSize`, which `u32` and `u64` implement. This does not work, because a trait is *open*: any code can later implement it for another type. If someone wrote `impl PointerSize for u8`, the bound would accept it, and a memory with 8-bit addresses would type-check.

WX therefore adds a *typeset*: a closed set of types, listed in its declaration (@fig:typeset-vs-trait).

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

The `Memory` trait uses this typeset to restrict `Size` and define operations in terms of it. The trait below is shortened:

```wx
pub trait Memory {
    type Size: PointerSize;
    const PAGE_SIZE: Self::Size = 65536;

    func grow(self: Self, delta: Self::Size) -> Self::Size::Signed { .. }
    func size_pages(self: Self) -> Self::Size { .. }
}
```

`type Size: PointerSize` says that every memory's address type is `u32` or `u64`. `PAGE_SIZE` is an associated constant, and `grow` and `size_pages` map directly to the WebAssembly instructions `memory.grow` and `memory.size`. A program cannot implement `Memory` for its own types, because these operations need a real WebAssembly memory behind them.

=== Globals and explicit access <sec:global-access>

Globals use the same item-and-trait mechanism. For `global mut count: i32 = 0;`, the compiler implements `Global` with `type Value = i32` and also implements `GlobalMut`. The first trait provides `get`, and the second adds `set`. An immutable global, such as the imported `step` in @lst:wx-tour, gets only `Global`, so it has no `set` method.

The traits below are shortened to show their associated value type and operations. The bounds that restrict which values a global can hold are explained in @ch:stack-values.

```wx
pub trait Global {
    type Value;

    func get(self: Self) -> Self::Value {
        global_get(self)
    }
}

pub trait GlobalMut: Global {
    func set(self: Self, value: Self::Value) {
        global_set(self, value)
    }
}
```

The functions `global_get` and `global_set` provide typed access to the corresponding WebAssembly instructions (@ch:intrinsics). `GlobalMut: Global` means that every writable global also supports reading.

The name `count` identifies the global item; `count.get()` produces its stored `i32` value. The arithmetic in `count.get() + 1` therefore operates on an ordinary integer, while `get` and `set` explicitly identify access to module state. A local variable such as `next` holds a value within one call and can be used directly in expressions.

This distinction is deliberate. Reading a mutable global observes state that other calls or the host can change, and writing it changes that state. The extra syntax makes both operations visible in the source. Reading an immutable global does not have the same dependence on changing state, but uses the same access method for consistency. Keeping global access in functions also provides a basis for future effect tracking, where effect information can be attached to those calls.

Generic code uses the same methods. The counter update in @lst:wx-tour can be written as a function that accepts any mutable global holding an `i32`:

```wx
func adjust<G: GlobalMut where { Value = i32 }>(g: G, delta: i32) -> i32 {
    local next = g.get() + delta;
    g.set(next);
    next
}

func increment() {
    local next = adjust(count, host::step.get());
    host::log(next);
}
```

The bound `G: GlobalMut` provides both methods, and `Value = i32` fixes the stored value type so that addition is valid. Passing `count` supplies its item value, whose type identifies the global; it does not copy the stored integer. The compiler infers `G` from that argument. The same function can update another mutable `i32` global, including an imported one. Passing the immutable `host::step` as the first argument is rejected because it does not implement `GlobalMut`.

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

Exports work in the other direction: they name the items the host can use. An entry can be written as its own statement, or several entries can share an `export { ... }` block, and a package may use either shape or both:

```wx
export heap as "memory";
export sum as "add";

export { product, sum as "plus" };
```

The name after `as` is the external name. Inside the program, an item has a name that follows wx's identifier rules, but a WebAssembly export name is any string. A host may expect a name that is not a valid identifier. An alias lets the source keep its own name while the module presents the name the host expects. Here `sum` is exported twice, once as `add` and once as `plus`. An entry without `as` keeps its own name.

The compiler assigns all indices at code generation, imports first. A program never writes or computes an index, so adding an import never changes existing code.

== Multiple memories at the host boundary <sec:multi-memory-host>

An address passed to an imported function is only a number. To read the bytes at that address, the host must also have access to the memory containing them. A module can import a memory supplied by the host or define one and export it. Either way, the party receiving access can read or write the *whole memory*, not just the range passed to a function #fnote("wasm-spec-modules"). If a module exports the memory holding its internal data merely to pass a string, that data becomes accessible to the host too. The multiple-memories proposal names separation of public and private data as one motivation #fnote("wasm-multi-memory").

WX gives the exchange its own memory:

```wx
memory host_io: u32;
memory private_mem: u32;

import "host" as host {
    func write(message: super::host_io::&[u8]);
}

func main() {
    host::write("hello world");
}

export { main, host_io as "memory" }
```

The parameter type `host_io::&[u8]` fixes the string literal's memory. The host receives its offset and length and reads those bytes from the exported `host_io`. `private_mem` is not exported, so the host has no direct memory access to it. A value of type `private_mem::&[u8]` cannot be passed to `host::write`: the two pointers name different memories, and the mismatch is checked by the type system (@sec:pointers-memory). The same separation can use a host-supplied `host_io` imported into the module, provided the host reserves that entire memory for exchange. WX's memory names are a source-level guarantee; the host function must still interpret the numeric offset against the agreed memory.

== Tables and tags: designed, not implemented <sec:items-kinds>

Tables and tags are not implemented. The design follows the same pattern. A table would be declared like a memory, and the compiler would implement a trait that gives its operations (`table.get`, `table.set`, `table.grow`). A handle to a table slot would carry its table in its type, as a pointer carries its memory. A tag would be declared like a struct with a payload, and the compiler would implement a `Tag` trait for it. These designs are kept short here because none of them can be tested yet.

== One mechanism <sec:items-summary>

Every part of this chapter uses the same mechanism: a short declaration creates an item with its own zero-sized type, and the compiler implements a trait for that type (@tbl:items-mechanism). The trait gives the item's shape as associated types, and its operations as methods. Nothing in the type checker is specific to memories or globals except the code that writes these impls.

#figure(
  booktable(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    table.header([Declaration], [Type], [Impl written by the compiler]),
    table.hline(stroke: 0.5pt),
    [`memory heap: u32;`],
    [`heap`],
    [`Memory` with `Size = u32`],
    [`global mut count: u32 = 0;`],
    [`count`],
    [`Global` with `Value = u32`, and `GlobalMut`],
    [`func add(a: i32, b: i32) -> i32`],
    [`add`],
    [`Call` with `Args = (i32, i32)`, `Result = i32` (@ch:calls)],
  ),
  caption: [Declarations, their item types and the traits the compiler implements for them.],
) <tbl:items-mechanism>

The next chapters use the same mechanism for things that are not declarations. @ch:stack-values describes a trait that the compiler implements for every type, and @ch:calls a trait it implements for every function.
