#import "../../template.typ": booktable, muted, todo

= Stack Values: Types on the WebAssembly Stack <ch:stack-values>

@tbl:kinds gave a global's shape as a value type and a mutability. In WebAssembly, the value type is one of a few types the platform defines. In WX, a global is declared with a WX type, and WX has many more types: structs, tuples, enums, pointers and slices. This chapter answers which of them a global may hold. The answer needed a more general concept: a description of how any WX type is held on the WebAssembly stack. The same description later decides how values are reinterpreted (@sec:transmute) and what a function's WebAssembly signature is (@ch:calls).

== A global holds one value <sec:one-value>

A WebAssembly global holds exactly one value of one value type @wasm-spec-modules:

```wat
(global $count (mut i32) (i32.const 0))
(global $scale f64 (f64.const 1.5))
```

The value types are the numbers `i32`, `i64`, `f32` and `f64`, the vector type `v128`, and the reference types. There are no tuple or struct globals. A function can return several values (multi-value), but a global holds one.

WX types do not map to value types one to one. `u8`, `u16`, `u32`, `Bool` and `Char` are all held as one `i32`, and so is a pointer into a 32-bit memory. Other types are held as several values, or as none:

```wx
struct Meters(u32);            // one i32
struct Point(x: u32, y: f64);  // an i32 and an f64
global origin: Point = Point(0, 0);
```

`Meters` fits in a global. `Point` does not, and neither does a slice, which is an address and a length. The compiler has to decide this for every global, and the rule should meet three requirements:

- *One item, one entity.* A WX global must be exactly one WebAssembly global, so the host sees what was declared when the global is imported or exported.
- *Generic code.* WX checks a generic function once, for all possible type arguments. Code that is generic over a global (`G: Global`) must know that `G::Value` fits in one value without knowing what `G::Value` is.
- *No special case.* The rule should use the mechanism that already describes items (@sec:items-summary), not a check written only for globals.

== Approaches considered <sec:stack-approaches>

*Splitting the global.* The compiler could turn `global origin: Point` into two WebAssembly globals, one per field. But then one item becomes two entities, and an exported `origin` becomes two exports with names the compiler invented. The host would need to know WX's rules to use it.

*Storing the value in memory.* The global could hold a pointer to the value in linear memory. But then it needs a memory, it is read with a load instead of `global.get`, and the host sees an address. A program that wants this can already write it, with a global of pointer type.

*A marker trait.* An earlier version of WX had a trait, `ValueType`, that the compiler implemented for every type held as exactly one value, and it required `Global::Value: ValueType`. This met the first two requirements. But it could only answer yes or no. It could not say that `Meters` is held exactly like `u32`, so it was useful for globals and for nothing else. The design that replaced it answers a more general question.

== Stack representation <sec:stack-repr>

The general question is: how is a value of a given type held on the WebAssembly stack? WX answers it with a trait that the compiler implements for every type:

```wx
pub trait StackValue {
    type Repr;
}

pub typeset StackScalar { i32, i64, f32, f64, funcref }
```

`Repr` is the list of WebAssembly values a type is held as, written with WX's own primitive types. A type held as one value has that value's type as its `Repr`. A type held as several values has their tuple, and a type held as none has `()`. WX has no tuple of one element, so a single value and a tuple of it are the same type. @tbl:repr gives examples.

#figure(
  booktable(
    columns: (auto, auto),
    align: (left, left),
    table.header([Type], [`Repr`]),
    table.hline(stroke: 0.5pt),
    [`u8`, `i16`, `u32`, `i32`, `Bool`, `Char`],
    [`i32`],
    [`u64`, `i64`],
    [`i64`],
    [`f32`, `f64`],
    [`f32`, `f64`],
    [`funcref`, `func(A) -> R`],
    [`funcref`],
    [an enum],
    [the `Repr` of its representation type],
    [`M::*T`, `M::&T`],
    [`M::Size`'s (an address)],
    [`M::&[T]`],
    [`M::Size`'s, twice (an address and a length)],
    [`Meters(u32)`],
    [`i32`],
    [`Point(x: u32, y: f64)`, `(u8, f64)`],
    [`(i32, f64)`],
    [`()`, an item's type],
    [`()`],
  ),
  caption: [The stack representation of some WX types. Parts are flattened in declaration order, and zero-sized parts are dropped.],
) <tbl:repr>

No `impl StackValue` is written anywhere. The compiler computes the answer from the type's structure when it is needed, in the same way it implements `Memory` for a declared memory. A struct or a tuple is its parts, flattened, in declaration order, with zero-sized parts dropped. Every type implements `StackValue` except `!` (the type with no values) and types that contain it.

Because no impl is recorded, a short path such as `Point::Repr` does not work: the compiler looks for `Repr` in the impls of `Point` and finds none. The trait must be named, as in `<Point as StackValue>::Repr`, which also says where the representation comes from. Bounds such as `where { Repr = T::Repr }` work as usual, so this only affects code that names a concrete type's representation directly.

`StackScalar` is a typeset (@sec:typesets) of the types of one WebAssembly value. `v128` is missing only because WX does not support SIMD yet. `funcref` is a WebAssembly function reference of any signature.

*Stack, not memory.* `StackValue` describes values on the stack: in locals, parameters, results and globals. How a value is stored in linear memory is a different question, with alignment, padding, and a field order that the compiler may change to reduce padding. `Repr` ignores all of that and always uses declaration order.

== Globals as a bound <sec:globals-bound>

With `Repr`, the rule for globals is one bound in the `Global` trait:

```wx
pub trait Global {
    type Value: StackValue where { Repr: StackScalar };

    func get(self: Self) -> Self::Value {
        global_get(self)
    }
}
```

The value of a global must be held as exactly one WebAssembly value. For `global origin: Point = ..` the compiler writes `impl Global for origin { type Value = Point; }`, and this impl must satisfy the trait's bounds like any other impl. `Point` does not, and the error is the normal error for an unmet bound (@fig:global-diagnostic).

#figure(
  kind: raw,
  supplement: [Listing],
  text(size: 0.8em)[```text
  error[E2063]: the trait bound `(i32, f64): StackScalar` is not satisfied
     ┌─ /main.wx:20:16
     │
  10 │ trait Global { type Value: StackValue where { Repr: StackScalar }; }
     │                                                     ----------- required by a bound in `Global`
     ·
  20 │ global origin: Pair = Pair(0, 0);
     │                ^^^^ the trait `StackScalar` is not implemented for `(i32, f64)`
  ```],
  caption: [A global of two values is rejected (`struct Pair(x: u32, y: f64)`). The test uses a minimal standard library, so `Global` is written on one line. Compiler at `186ba25`, branch `tir-refactor`, 2026-10-30.],
) <fig:global-diagnostic>

All three requirements hold. A WX global is one WebAssembly global, so `Meters`, an enum, a pointer or a function reference can be a global, and `Point` cannot. Generic code gets the guarantee from the trait: for any `G: Global`, `G::Value` is one value. And the rule is not special code for globals. It is an associated-type bound, the same mechanism that limits `Memory::Size` to `PointerSize`.

== Reinterpreting a value <sec:transmute>

`ValueType` could only say whether a type fits in a global. `Repr` says what a type is on the stack, so it can also say when two types are held the same way. Then a value of one type can be used as the other without running any instruction:

```wx
pub func transmute<
    T: StackValue,
    U: StackValue where { Repr = T::Repr },
>(value: T) -> U;
```

`transmute` turns a `T` into a `U` when both are held as the same WebAssembly values. It has no body, and at run time it does nothing. `Meters` to `u32`, `Point` to `(u32, f64)`, and a pointer into a 32-bit memory to `u32` are accepted. `u32` to `u64` is rejected: their representations are `i32` and `i64`, and changing one into the other is an instruction (`i64.extend_i32_u`), which WX offers as a function (@ch:intrinsics).

Because `Repr` keeps declaration order, `transmute` cannot reorder fields. Turning `(u8, u64)` into `(u64, u8)` is rejected (@fig:transmute-diagnostic). If `Repr` followed the memory layout, which sorts fields by alignment, both tuples would be `(i64, i32)`, and the conversion would be accepted while it silently swapped the fields.


#figure(
  kind: raw,
  supplement: [Listing],
  text(size: 0.8em)[
    ```text
    error[E2112]: type mismatch resolving `<(u64, u8) as StackValue>::Repr == (i32, i64)`
       ┌─ /main.wx:21:40
       │
    14 │     U: StackValue where { Repr = T::Repr },
       │                                  ------- required by this equality in `transmute`
       ·
    21 │ func swap(x: (u8, u64)) -> (u64, u8) { transmute(x) }
       │                                        ^^^^^^^^^ expected `(i32, i64)`, found `(i64, i32)`
    ```
  ],
  caption: [A `transmute` that would reorder fields is rejected. Same test setup and commit as @fig:global-diagnostic.],
) <fig:transmute-diagnostic>

*A limitation.* `transmute` checks the representation, not the values. `transmute::<u8, Bool>(2)` is accepted, although `Bool` has only the values 0 and 1, and so is an enum made from a number that is not one of its variants. In Rust, `transmute` is `unsafe` for this reason. WX has no `unsafe` yet; marking such operations is planned as part of the effect design.

Before `transmute`, WX had an `as` expression. It did two different things: it gave a literal its type (`5 as u8`), and it reinterpreted a value. Now these are separate. A type ascription, `(5: u8)`, gives a value its type and converts nothing. `transmute` reinterprets, and an instruction changes a representation.

`transmute` also lets the standard library type every instruction exactly as WebAssembly reads its operands. `i32.add` adds two `i32` values and does not know about signedness, so the function for it takes two `i32`. Addition for `u32` reinterprets on the way in and out:

```wx
impl Add for u32 {
    #[inline]
    func add(self: Self, rhs: Self) -> Self {
        transmute(i32_add(transmute(self), transmute(rhs)))
    }
}
```

== Generic code <sec:stack-generic>

WX checks a generic function once, with its type parameters unknown. A `transmute` in a generic function must therefore be correct for every possible type argument:

```wx
struct Wrap<T>(T);

func unwrap<T: StackValue>(w: Wrap<T>) -> T {
    transmute(w)
}
```

Here the compiler must show that `Wrap<T>` and `T` have the same representation while `T` is unknown. For an ordinary trait, this would follow from an impl that works for any `Wrap<T>`:

```wx
impl<T: StackValue> StackValue for Wrap<T> {
    type Repr = T::Repr;
}
```

`StackValue` behaves as if the compiler had written such an impl for every struct and tuple, but it does not build any of them.

For a type with several parts, such an impl cannot be written. The representation of `Pair<T, u32>` is not `(T::Repr, i32)`: with `T = (u8, u8)` that type would be `((i32, i32), i32)`, a nested tuple, while the real representation is the flat `(i32, i32, i32)`. WX has no type for "the concatenation of two tuples", and I did not want to add one. Instead, the compiler rewrites the type into a *normal form* that is flattened as far as it is known: nested tuples and structs are flattened, known scalars are replaced by their representation, zero-sized parts are dropped, and each unknown part stays as one element (@tbl:repr-normal).

#figure(
  booktable(
    columns: (auto, auto),
    align: (left, left),
    table.header([Written], [Normal form]),
    table.hline(stroke: 0.5pt),
    [`<Wrap<T> as StackValue>::Repr`],
    [`<T as StackValue>::Repr`],
    [`<Pair<T, u32> as StackValue>::Repr`],
    [`<(T, i32) as StackValue>::Repr`],
    [`<(T, u32) as StackValue>::Repr`],
    [`<(T, i32) as StackValue>::Repr`],
    [`<Point as StackValue>::Repr`],
    [`(i32, f64)`],
  ),
  caption: [Normal forms of `Repr`. Without an unknown part the result is the flat tuple. With one, the projection is kept over a flattened type.],
) <tbl:repr-normal>

Two representations are then compared like any two types: both are normalized and the results are compared. No other part of the compiler needs to know about `StackValue`. `unwrap` is accepted, and so is a `transmute` between `Pair<T, u32>` and `(T, u32)`. Once `T` is known, the rest reduces like any other type: with `T = (u8, u8)`, `<((u8, u8), i32) as StackValue>::Repr` is `(i32, i32, i32)`. Each rewriting step keeps the flattened result the same for every possible `T`, so equal normal forms always mean equal representations. The opposite is not always true: `(T, U)` and `(U, T)` are not equal in generic code, although they are equal when `T` and `U` are the same type.

== Comparison <sec:stack-comparison>

#todo[Verify each row against the language's documentation and add citations. The rows are from knowledge, not from the Chapter 2 probes: probe 10 only declares `i32` globals.]

@tbl:stack-comparison compares WX with three languages from @ch:background on the two questions of this chapter.

#figure(
  booktable(
    columns: (auto, 1fr, 1fr),
    align: (left, left, left),
    table.header([Language], [Global of a compound type], [What reinterpretation checks]),
    table.hline(stroke: 0.5pt),
    [Rust],
    [linear memory; a `static` is never a WebAssembly global],
    [`transmute`: equal size in bytes; `unsafe`],
    [Zig],
    [linear memory],
    [`@bitCast`: equal size in bits],
    [AssemblyScript],
    [a WebAssembly global holding a pointer to the object],
    [`reinterpret<T>`: an integer and a float of the same width],
    [WX],
    [rejected; a global is one WebAssembly value],
    [`transmute`: the same values on the stack, in the same order],
  ),
  caption: [Globals of compound types and reinterpretation in WX and three other languages.],
) <tbl:stack-comparison>

The second column follows from the first. Rust and Zig keep values in linear memory, where any value can be read back as bytes, so equal size is the only thing they can check. WX reinterprets values on the stack, so it checks the actual list of WebAssembly values, and it also rejects a reordering that keeps the size.

// Status (2026-10-30, `tir-refactor` at `186ba25`): StackValue, StackScalar, transmute and the Global bound are
// implemented in the type checker and tested. Codegen is disabled on the branch, so nothing using them has been
// compiled to Wasm yet. The lowering of values to the stack must follow declaration order; the previous MIR
// flattened in physical (layout) order.
