#import "../../template.typ": booktable, muted, todo

= Intrinsics: Instructions as Functions <ch:intrinsics>

The previous chapters gave WebAssembly's entities, values and calls a place in the type system. This chapter is about instructions. @sec:synthesis asked whether a language can give typed access to the platform's instructions, so that the compiler checks every use. WX's answer is plain: an instruction is a function in the standard library, with a signature and no body, and a program calls it like any other function.

== Instructions in the standard library <sec:intrinsic-functions>

Languages reach the instructions their source language does not cover in two ways. Inline assembly reaches all of them, but the compiler checks none of it (@sec:synthesis). Builtin functions are checked, but the compiler defines their names and types, they often take an entity as a plain integer, and they cover only the instructions their authors chose.

In WX, an *intrinsic* is a function declared without a body in the standard library:

```wx
pub func i32_add(a: i32, b: i32) -> i32;
pub func u32_div(a: u32, b: u32) -> u32;
pub func i64_extend_i32(value: i32) -> i64;
pub func f32_reinterpret_i32(value: i32) -> f32;
pub func trap() -> !;
```

The declaration is all a program sees. The compiler maps each one to its WebAssembly instruction. Nothing else about it is special: it is found by name resolution, checked against its signature, and can be wrapped or kept private to the library. A language server shows its signature like any other function.

Each signature is the instruction's own, as @sec:transmute explained. `i32.add` reads two `i32` values, so `i32_add` takes two `i32`. Where WebAssembly has separate signed and unsigned instructions, the library has separate functions: `i32_div` takes `i32` and `u32_div` takes `u32`. A change of representation is always a named function (`i64_extend_i32`, `i32_wrap_i64`, `f32_reinterpret_i32`) and never an implicit conversion, because each one is a different instruction.

Adding a new instruction means adding one declaration to the library and its mapping to the compiler. No new syntax or kind of item is needed, so coverage can grow one instruction at a time.

// Not settled (2026-10-30): how the compiler recognizes a bodiless std function as an intrinsic. Types use
// "a reserved name of the right kind declared in std" (`IntrinsicDefs`); functions have no rule yet, and a bodiless
// function in user code is not diagnosed.

== Entities as arguments <sec:intrinsic-entities>

Many instructions name an entity: `memory.size` and `memory.grow` name a memory, `global.get` a global. In the binary format this is an index written into the instruction. An intrinsic for such an instruction takes the entity as a value of its item type (@sec:items-as-types):

```wx
pub func memory_size<Mem: Memory>(mem: Mem) -> Mem::Size;
pub func memory_grow<Mem: Memory>(mem: Mem, delta: Mem::Size) -> Mem::Size::Signed;
pub func memory_fill<Mem: Memory>(dst: Mem::*u8, val: u8, len: Mem::Size);
```

The argument `mem` is zero-sized. It takes no space on the stack, and the compiler reads which memory it is from its type and writes the index into the instruction. The other parameters are typed by the same memory: `delta` is a `u32` for a 32-bit memory and a `u64` for a 64-bit one. `memory.grow` returns the old size, or $-1$ if the memory cannot grow, so its result is the signed type of the same width (`Size::Signed`, `i32` or `i64`). No intrinsic takes an integer where an entity is expected, so an index never appears in a program as a value. This completes the goal of @sec:identity-shape: a program never uses an entity's index as an integer.

When an instruction uses two entities, the signature says how they must relate. `memory.copy` copies between two memories, which must have the same address type:

```wx
pub func memory_copy<
    Size: PointerSize,
    SrcMem: Memory where { Size = Size },
    DstMem: Memory where { Size = Size },
>(dst: DstMem::*u8, src: SrcMem::&u8, len: Size);
```

One declaration covers a copy inside one memory and between any two memories, and the memories come from the pointer types. A copy from a 32-bit into a 64-bit memory is rejected with the normal error for an unmet bound (@fig:copy-diagnostic).

#figure(
  kind: raw,
  supplement: [Listing],
  text(size: 0.8em)[
  ```text
  error[E2112]: type mismatch resolving `<big as Memory>::Size == u32`
       ┌─ /main.wx:2380:55
       │
  2079 │     DstMem: Memory where { Size = Size },
       │                                   ---- required by this equality in `memory_copy`
       ·
  2380 │ func wrong(dst: big::*u8, src: heap::&u8, len: u32) { memory_copy(dst, src, len) }
       │                                                       ^^^^^^^^^^^ expected `u32`, found `u64`
  ```
  ],
  caption: [Copying from a 32-bit memory (`heap`) into a 64-bit one (`big`). The test appends its source to the standard library, hence the line numbers. Compiler at `186ba25`, branch `tir-refactor`, 2026-10-30.],
) <fig:copy-diagnostic>

== From instruction to method <sec:intrinsic-layers>

Most programs never call these functions directly. The library wraps them in default methods of the traits that the compiler implements for each item (@sec:why-traits):

```wx
pub trait GlobalMut: Global {
    func set(self: Self, value: Self::Value) {
        global_set(self, value)
    }
}
```

So there are three layers, and each one is ordinary code over the layer below: the intrinsic, a trait method that calls it, and user code that calls the method, such as `count.set(count.get() + 1)`. The layers let the library decide what a program can do. `global_get` and `global_set` are private to the library, so a program reads and writes a global only through `get` and `set`, and only a `global mut` has `set`. The instruction underneath is still one `global.set`. The restriction comes from which functions are visible, not from an extra check in the compiler.

`Memory` has the same kind of methods, `grow` and `size_pages`, over `memory_grow` and `memory_size`. A call like `heap.grow(1)` needs a memory used as a value, which the current type checker does not support yet (@sec:items-as-types).

Operators work the same way. `a + b` is a call of the `Add` trait's `add` method, and the library implements the operator traits for each primitive type with intrinsics (@sec:transmute shows `u32`). A program's own types implement the same traits, so `+` on a user's `Vec2` and on `u32` use the same mechanism.

== Trapping <sec:trap>

`trap` is WebAssembly's `unreachable` instruction: execution stops with a trap. Its return type is `!`, the type with no values. An expression of type `!` can be used where any type is expected, so a trap can stand in any position:

```wx
func expect(ok: Bool, value: u32) -> u32 {
    if ok { value } else { trap() }
}
```

`break` and `return` also have type `!`, because they do not complete either. So `trap` needs no rule of its own: it is just a function that returns `!`.

== Memory access is syntax <sec:memory-access>

Loads and stores are the most common instructions, and WX does not expose them as functions. They are written as operations on *places*, locations in memory reached through a pointer (@tbl:places).

#figure(
  booktable(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    table.header([Written], [Meaning], [Instruction]),
    table.hline(stroke: 0.5pt),
    [`p.*`], [the place `p` points at], [a load when read, a store when written],
    [`p.field`], [a field of that place], [the same, at the field's offset],
    [`xs[i]`], [element `i` of a slice or array], [the same; traps if `i` is out of bounds],
    [`place.&`], [a pointer to a place], [none; only the address is computed],
  ),
  caption: [Memory access in WX. The memory is the one in the pointer's type (@sec:pointers-memory).],
) <tbl:places>

```wx
func read(p: heap::&u32) -> u32 { p.* }
func write(p: heap::*u32) { p.* = 5; }
```

The memory and the size of the access come from the pointer's type: `heap::&u32` reads four bytes from `heap`. The same code with a pointer into another memory compiles to the same instruction with another memory index.

All these operations are written after their operand, so a chain reads from left to right in the order the steps happen: `n.*.next.*.value` follows two pointers, where C needs `(*(*n).next).value`. Zig made the same choice for `p.*`. A program cannot overload these operations for its own types, so every `.*` is a memory access and never a call of user code.

== Comparison <sec:intrinsic-comparison>

#todo[Verify each row against the language's documentation and cite: clang's WebAssembly builtins, Rust's `core::arch::wasm32`, Zig's language reference, AssemblyScript's builtins.]

#figure(
  booktable(
    columns: (auto, auto, 1fr),
    align: (left, left, left),
    table.header([Language], [Growing a memory], [The memory is named by]),
    table.hline(stroke: 0.5pt),
    [C/C++ (clang)], [`__builtin_wasm_memory_grow(0, n)`], [an integer constant],
    [Rust], [`core::arch::wasm32::memory_grow::<0>(n)`], [an integer constant generic argument],
    [Zig], [`@wasmMemoryGrow(0, n)`], [an integer],
    [AssemblyScript], [`memory.grow(n)`], [nothing; there is one memory],
    [WX], [`memory_grow(heap, n)`], [the memory item, a value of its own type],
  ),
  caption: [Growing a memory in WX and four other languages.],
) <tbl:intrinsic-comparison>

All these languages offer the instruction as a builtin and check its operands. The difference is how the memory is named. When the memory is an integer, the type system cannot tell a memory index from any other number, and the memory's address type (32 or 64 bits) cannot follow from it. In WX the memory is an item, so the other operands are typed by that memory, and a program never handles its index.
