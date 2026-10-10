#import "../../template.typ": booktable, muted, todo

= Items: Representing the Platform's Entities <ch:items>

== Entities, identity and shape <sec:identity-shape>

@fig:entities found WebAssembly's own entities — memories, tables, globals and tags — to be the weakest point across every surveyed language: none of them gives these kinds a first-class, typed value that a program can hold, pass around, and have checked against misuse, the way a plain function reference already gets almost everywhere (@sec:synthesis). Growing a WebAssembly module one feature at a time makes the reason concrete.

=== WebAssembly index spaces

A WebAssembly module can define and export a function directly:

```wat
(module
  (func (result i32) i32.const 42)
  (export "run" (func 0)))
```

The export refers to the function by its index. WebAssembly places imported functions before defined ones in the function index space @wasm-spec-modules, so the index of a defined function depends on how many functions are imported ahead of it — adding an import can shift every index already written:

```wat
(module
  (import "env" "log" (func (param i32)))
  (func (result i32) i32.const 42)
  (export "run" (func 1)))
```

The defined function is now index 1, purely because the import took index 0; nothing about the function itself changed. WAT's symbolic names exist to absorb exactly this kind of change: a `$name` resolves to its index once, when the module is encoded into bytes, so the source text never has to track a renumbering by hand:

```wat
(module
  (import "env" "log" (func $log (param i32)))
  (func $run (result i32) i32.const 42)
  (export "run" (func $run)))
```

Memories, tables, globals and tags are indexed the same way, each in a space of its own, independent of functions and of each other:

```wat
(module
  (memory $mem 1)
  (func $run (result i32) i32.const 42)
  (export "run" (func $run))
  (export "mem" (memory $mem)))
```

`$mem` is index 0 because it is the only memory declared.

=== Entity representation

So far, `$mem` is a name for a number, exactly the way `$run` is one. That was harmless for `$run` — nothing above calls it anything but `$run`. It stops being harmless the moment wx needs to let a program hold `$mem` as a real value: pass it to a function, check that it is the right memory, grow it. What type should `$mem` have, once it is something a program writes rather than something an export line points at?

One option is to expose the index directly. Zig's `@wasmMemoryGrow` builtin accepts a `u32` memory index @zig-wasm-builtins, so the type system does not distinguish that index from other integers. This is reasonable for a low-level builtin, but it would leave wx programs responsible for keeping entity indices separate from ordinary numeric values — if `$mem` became a `u32` the same way, nothing would mark it apart from, say, a loop counter that also happened to be a `u32`.

The opposite problem shows up on `$run`, not `$mem`. Suppose a second function joins the module:

```wat
(func $reset (result i32) i32.const 0)
```

`$run` and `$reset` have the same signature, `() -> i32`, and WebAssembly never confuses them — they sit at different indices. A binding whose type was only that signature would: anything typed `() -> i32` would do, including a call site that meant `$run` and was handed `$reset` instead, with nothing left to object.

Neither fix solves the other's problem: an integer doesn't say what kind of entity it is, and a signature doesn't tell two entities of the same kind apart. A binding needs both — the entity's kind, and its own identity within that kind — without turning the index into something a program controls or passes around. The index could still be made inspectable from the item, but it must never be assigned by a developer, or handled as the entity itself.

=== Identity and shape

Call the first of those two requirements an entity's *identity*: its kind, and that it is this declaration and no other. In the compiler, identity resolves to a kind together with an index into that kind's own space — `$run`'s is `(function, 1)`, `$mem`'s is `(memory, 0)` — but that index is only settled once the whole module is assembled. A source-level representation of identity cannot depend on knowing it any earlier, and must never expose it as a number a program computes, stores, or compares.

Call the second requirement an entity's *shape*: the structural information a use of it is checked against. @tbl:kinds lists both, for the five kinds this chapter has touched.

#figure(
  booktable(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    table.header([Kind], [Identity], [Shape]),
    table.hline(stroke: 0.5pt),
    [Function],
    [(function, index)],
    [signature],
    [Global],
    [(global, index)],
    [value type, mutability],
    [Memory],
    [(memory, index)],
    [shared flag, index type],
    [Table],
    [(table, index)],
    [reference type, index type],
    [Tag],
    [(tag, index)],
    [signature],
  ),
  caption: [Identity and shape for the five kinds of entity this chapter covers.],
) <tbl:kinds>

Shape is not uniform across kinds, and the table is narrower than WebAssembly's own type for each one. A function's and a tag's shape is the signature a call is checked against; a global's is a value type plus mutability. A memory and a table also carry limits — a minimum and maximum size — in their full WebAssembly type, but a limit is checked once, when an import or instantiation is matched against what it declares, not against every later use the way a signature or value type is; how, or whether, wx's design surfaces limits at all is a question for where memories and tables are actually designed (@sec:why-traits, @sec:items-kinds), not this walkthrough.

What @fig:entities found missing, for memories, tables and tags, was never one of these shape properties — every surveyed language that touches WebAssembly at all type-checks *some* use of a memory or a table. What was missing was identity: a first-class value a program could hold that stayed distinct from every other value of the same kind. Globals come closest, since a declared global is at least always some binding in every surveyed language — just not one guaranteed to resist the mix-up a shared signature makes possible for functions and tags.

The discussion above establishes three design goals for WX:

- *Stable references* — adding imports or definitions must not require developers to update existing references manually.
- *Explicit module boundaries* — every entity kind must support definitions, imports and exports.
- *Distinct entity identities* — each entity must be distinguishable from other entities of the same kind without exposing its Wasm index as an ordinary integer.

== Pointers and memory identity <sec:pointers-memory>

=== Multiple memory address spaces

In most programming languages, a pointer's type describes what it points to. For example, `*u8` represents a pointer to a byte. This is usually enough because pointers share an address space: the type needs to describe the pointed-to data, not which memory contains it.

WebAssembly allows a module to declare multiple independent memories (@wasm-multi-memory). Each has its own address space, and load and store instructions specify which memory they access. Two pointers can then both have type `*u8` while referring to addresses in different memories. Their pointee types are identical, but the compiler must generate different load instructions depending on which memory each pointer belongs to. The pointer's type alone does not provide that information.

=== Memory identity in pointer types

One possible solution is to represent a pointer as a *fat pointer* containing both a memory index and an offset. This would allow the memory identity to be carried at runtime, but would require storing it alongside the address. WX instead associates the memory with the pointer's type, allowing the compiler to determine the target memory during code generation without runtime overhead for tracking memory identity.

`M::*u8` denotes a pointer to a byte in memory `M`, where `M` is a declared memory item. Unlike `*u8`, this type distinguishes pointers into different memories: a pointer of type `M::*u8` cannot be used where a pointer into another memory is expected, even though both point to bytes. Since WebAssembly load and store instructions specify their target memory, the compiler can determine which memory to access from the pointer's type. Memory identity is resolved during compilation rather than carried as a runtime value.

=== Table identity and references

Tables raise a related but distinct case. Unlike linear memory, whose contents can be accessed as bytes, a WebAssembly table stores typed references that cannot be read or written as raw byte sequences. This distinction preserves the abstraction of references: their internal representation is implementation-dependent, and a module cannot inspect or forge that representation by manipulating bytes.

The same principle applies to table identity. A handle into a table must identify which table it belongs to, so it cannot be used as though it referred to another table. In WX, a table-qualified type can express this relationship, just as `M::*u8` identifies both the pointee type and its memory.

Pointers in WX therefore represent more than addresses: their types identify both what they point to and which memory contains it. Table-qualified types follow the same principle, associating references with the table they belong to.

== Item declarations and module boundaries. <sec:items-imports>

// NOTE: examples use `func`, tracking Wasm/WAT naming, ahead of a planned
// rename of the compiler's current `fn` keyword — not a typo, don't "fix".
WX retains WebAssembly's terminology and entity model, using keywords such as `func`, `global` and `memory` to declare the corresponding entities. Instead of WAT's nested S-expressions, WX uses conventional declarations with explicit names, types and bodies. Its syntax draws on familiar elements from languages such as Rust and TypeScript while keeping WebAssembly concepts recognizable.

For example, a module can declare a memory and a function as follows:

```wx
memory mem: u32;
func run() -> i32 { 42 }
```

Globals follow the same declaration style, with mutability specified explicitly:

```wx
global counter: i32 = 0;
global mut total: i32 = 0;
```

Entities can be exposed to the embedding environment through an export block. Exports may retain an entity's name or assign it a different external name:

```wx
export { mem, run }
export { mem as "memory" }
```

Imports use a similar structure. The declaration specifies the expected entity, while the import identifies the external module that provides it:

```wx
import "env" as env {
    func log(i32);
    func random() -> i64;
    global counter: i32;
    global mut total: i32;
}
```

An imported function is declared by its signature, without a body, and an imported global has no initializer. The imported entities can then be referenced through the `env` namespace, as in `env::log` and `env::counter`.

Although WX exposes WebAssembly entities directly, developers do not need to manage their binary indices or arrange declarations around them. The compiler assigns indices during code generation, accounting for imports and local definitions automatically.

== Item identity as a type <sec:items-as-types>

An item's identity must be available to the compiler, but it does not need to be represented at runtime. Once compilation resolves an item to its WebAssembly index, there is no need to carry that identity as runtime data. WX represents each item using a *zero-sized type*: a type whose values occupy no runtime storage, but whose identity remains meaningful during compilation.

This idea has precedents in existing languages. An empty struct, for example, defines a distinct type even though its values contain no data. Rust applies a similar idea to functions: each function definition has its own zero-sized function-item type, distinct from its function signature. This means that two functions with the same signature still have different types. However, when a function item is converted to a function pointer, its distinct function-item type is lost, even though the pointer still identifies the function at runtime.

WX takes this idea further by allowing an item's name to denote both a type and a value of that type. The name can therefore be used wherever a type is expected, as well as wherever a value is expected, without requiring a separate runtime representation of the item's identity. This preserves the distinction between entities throughout the language while leaving their eventual WebAssembly indices to code generation.

== Abstracting over memories <sec:why-traits>

With multiple memories, generic code needs a way to operate on different memory entities without losing information about their address types. For example, reading a memory's size requires a different result type depending on whether the memory uses 32-bit or 64-bit addressing. Without an abstraction, this operation would need separate functions for each address width.

WX uses traits to express this relationship. Its trait system draws on Rust's traits, which were influenced by Haskell's type classes. When a memory is declared, the compiler automatically implements a `Memory` trait for its item type, setting an associated type `Size` to match the memory's address type:

```wx
impl Memory for heap {
    type Size = u32;
}
```

This implementation is synthesized by the compiler from the memory declaration, so the developer does not need to write it manually. Nor can arbitrary user code implement `Memory`: its operations rely on actual WebAssembly memories, not merely on types that claim to represent them.

The trait allows generic code to operate on any memory while retaining its specific size type:

```wx
func memory_size<Mem: Memory>(mem: Mem) -> Mem::Size;
```

Here, `Mem` is the type of the memory item passed to the function, and `Mem::Size` resolves to the associated type defined by its implementation. The same function can therefore operate on memories with different address widths without requiring a common, less precise result type.

Traits also provide a way to associate operations with the entities they describe. WX exposes selected WebAssembly instructions through *intrinsics*: typed functions whose calls compile directly to the corresponding instructions. The `memory_size` function above is one such intrinsic. Its argument identifies the memory to query, allowing the compiler to select the appropriate WebAssembly instruction and memory index during code generation.

The `Memory` trait can provide a default implementation of `size` using this intrinsic:

```wx
trait Memory {
    type Size;

    func size(self) -> Self::Size {
        memory_size(self)
    }
}
```

Because the compiler synthesizes an implementation of `Memory` for each declared memory, every such memory inherits this method without requiring a separate implementation.

Consequently, `heap.size()` is an ordinary method call on the memory item's value. As established in @sec:items-as-types, `heap` is a value of its own zero-sized type. The call uses the trait's default method, which invokes the intrinsic. During compilation, the memory's identity determines the target of the WebAssembly instruction. This connects WX's entity types, trait system and intrinsic functions while keeping the source syntax independent of the underlying binary indices.

=== Typesets

`Size`, as written so far, is unconstrained — nothing says it can only be `u32` or `u64`, as opposed to any other type at all. That matters, because generic code written against `Mem::Size` needs to know what it is allowed to do with a value of that type, and "could be anything" gives it nothing to work with.

The obvious fix is a trait bound: require `Size` to implement some trait that only `u32` and `u64` happen to implement. That only works by coincidence, though. In a language like Rust, any other code, anywhere, could later implement that same trait for some third type, and the bound would quietly admit it — there is no way to say a set of implementers is closed, fixed once and never extended.

#figure(
  kind: raw,
  supplement: [Listing],
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1.2em,
    row-gutter: 0.6em,
    [*Closed — `typeset`*], [*Open — `trait`*],
    [
      ```wx
      typeset PointerSize { u32, u64 }

      impl PointerSize for u8 {}
      // error: typeset is closed
      ```
    ],
    [
      ```wx
      trait PointerSize {}
      impl PointerSize for u32 {}
      impl PointerSize for u64 {}

      impl PointerSize for u8 {} // compiles without error
      ```
    ],
  ),
  caption: [The same third `impl`, rejected by a closed `typeset` and accepted by an ordinary open trait.],
) <fig:typeset-vs-trait>

WX adds exactly that: a *typeset*. As @fig:typeset-vs-trait shows, `typeset PointerSize { u32, u64 }` declares a trait implemented by `u32` and `u64`, and rejects every other attempt to implement it — the set of members is fixed at the typeset's own declaration, not left open to whatever comes along later. It needs no concept beyond what a trait already is; it only closes a door a trait normally leaves open.

`Memory`'s associated type can now say exactly what it means: `type Size: PointerSize;` admits `u32` and `u64`, and nothing else, ever.

== The other kinds <sec:items-kinds>

#todo[Designed and not implemented; say so. Tags: a struct plus a result type, `Exception` as an explicit opt-in, not zero-sized. Tables: `table[func]` and `table[extern]`, the kind is compiler-internal and picks a trait, one table holds any funcref or externref. Host types: `type Node: extern;` with a required kind bound; no nominal function types. Handles and references as two layers, parallel to memory pointers and values; why Wasm has both. Where the operations live is for the next chapter (`h.*` is `table.get`, `as_ref()` is `ref.func`). Include the design story beats from plan.md as the reasoning.]
