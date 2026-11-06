#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote

= Functions and Calls <ch:calls>

A WebAssembly function type is a list of parameter types and a list of result types, such as `(param i32 i32) (result i32)`. The platform has no tuples and no structs: a function takes a flat list of values and returns a flat list of values. @ch:stack-values described how every WX type is held as such a list. This chapter shows how WX functions use that description. The rule is short: *every function takes exactly one value*, and its WebAssembly parameters are the representation of that value. The rest of the chapter follows from this rule, and its main result is that generic code can describe any function by two types, without variadic generics.

== The problem: describing any function <sec:call-trait>

Generic code over functions needs a type for a function's input. Function composition is the smallest example. `compose(f, g, x)` computes `g(f(x))`, and its signature must say that `g` accepts what `f` returns, for functions with any number of parameters:

```wx
func add(a: i32, b: i32) -> i32 { a + b }
func twice(x: i32) -> i32 { x * 2 }

compose(add, twice, (1, 2))  // twice(add(1, 2)) = 6
```

`add` takes two values and `twice` takes one. Rust describes functions with the `Fn` traits, which take the argument types as a tuple: `Fn<(i32, i32)>` for two arguments and `Fn<(i32,)>`, with a one-element tuple, for one. Because a Rust function does not really take a tuple, the compiler needs a special calling convention to spread the tuple into separate arguments, and user code cannot implement these traits on stable Rust. C++ and Swift use *variadic generics* instead: a type parameter that stands for a list of types, with its own syntax.

The aim was something simpler: to describe any function by two types, its arguments and its result, without variadic generics and without spread syntax.

== Every function takes one value <sec:one-parameter>

WX takes its rule from the ML family of languages: a function takes exactly one value, and a parameter list is notation for the type of that value (@tbl:parameter-type).

#figure(
  booktable(
    columns: (auto, auto),
    align: (left, left),
    table.header([Written], [The one value the function takes]),
    table.hline(stroke: 0.5pt),
    [`func() -> R`],
    [`()`],
    [`func(A) -> R`],
    [`A`],
    [`func(A, B) -> R`],
    [`(A, B)`],
    [`func((A, B)) -> R`],
    [`(A, B)`, the same type as the line above],
  ),
  caption: [The parameter type of a function, by its written parameter list.],
) <tbl:parameter-type>

WX identifies a one-element tuple with its element: `(T)`, `(T,)` and `T` are the same type. This keeps the argument type of `func(T)` equal to `T` and lets the same calling rule cover zero, one, or several parameters. Rust instead distinguishes `(T,)` from `T`.

With one value per function, the trait for anything callable needs only two associated types:

```wx
pub trait Call: StackValue {
    type Args: StackValue;
    type Result: StackValue;

    func call(self: Self, args: Self::Args) -> Self::Result;
}
```

The compiler implements `Call` for every function item, so `<add as Call>::Args` is `(i32, i32)` and `<twice as Call>::Args` is `i32`. It also implements it for every function reference type `func(A) -> R`. A program can implement `Call` for its own types, and then a value of that type can be called like a function: `v(a, b)` means `v.call((a, b))`.

Now `compose` is an ordinary generic function:

```wx
func compose<F: Call, G: Call where { Args = F::Result }>(
    f: F,
    g: G,
    x: F::Args,
) -> G::Result {
    g(f(x))
}
```

`F::Args` is whatever `f` takes: a pair for `add`, one value for `twice`, `()` for a function without parameters. The bound `Args = F::Result` says that `g` takes what `f` returns. Because several values and a tuple are the same thing, a function that returns a pair composes with a function of two parameters:

```wx
func divmod(a: i32, b: i32) -> (i32, i32) { (a / b, a % b) }

compose(add, twice, (1, 2))    // 6
compose(divmod, add, (17, 5))  // add(3, 2) = 5
```

The current type checker accepts both calls. No variadic type parameter, spread syntax or special calling convention was needed.

The rule has one surprising effect. `func g(p: (A, B))` and `func f(a: A, b: B)` have the same type, because both take an `(A, B)`. This shows only in generic code and in error messages, and it is exactly what `compose` needs.

== Calling a function <sec:filling>

A call still follows the declaration. A positional argument list gives one value for the parameters it fills:

- For `f(a: A, b: B)`, `f(x, y)` passes two arguments. `f(p)` with `p: (A, B)` passes both at once, because one value for several parameters is their tuple.
- For `g(p: (A, B))`, `g(x, y)` and `g((x, y))` are the same call.

The compiler never regroups a list to make it fit. For `add3(a: i32, b: i32, c: i32)` and `p: (i32, i32)`, the call `add3(p, 3)` is an error, and the compiler does not try to read `p` as two arguments. A method's receiver fills its first parameter, and the list fills the rest.

== Structs and named arguments <sec:structs>

In Rust, a tuple struct `struct Point(i32, i32)` is built by position, and a record struct `struct Point { x: i32, y: i32 }` by naming its fields. The two forms differ in declaration, construction, field access and patterns. In WX there is one struct form, and its fields are written like parameters, each with or without a name:

```wx
struct Point(x: i32, y: i32);
struct Pair(i32, pub u8);
```

A struct is built by calling its name, like a function from its fields to the struct: `Point(1, 2)`. The compiler checks a construction with the same code as a function call, so all the error messages about arguments are shared.

Once construction is a call, naming fields at construction means naming arguments of a call. So any call can name its arguments, with a group in braces:

```wx
func blit(dst: heap::*u8, src: heap::&u8, len: u32) { .. }

blit({ dst: buffer, src: image, len: 64 })
blit({ len, src: image, dst: buffer })    // the same call; `len` means `len: len`
Point({ x: 1, y: 2 })
```

Names make argument roles visible, such as the destination and source in `blit`. A call is either positional or named, never both. Names belong to the declaration and are never part of a type, so a function reference `func(A, B) -> R`, which has no names, is called by position (@fig:named-reference). Named arguments create no struct and do not change the WebAssembly signature.

#figure(
  kind: raw,
  supplement: [Listing],
  text(size: 0.8em)[
    ```text
    error[E2123]: a value of type `func(i32, i32) -> i32` is called through `Call`, so it is called by position
         ┌─ /main.wx:2378:47
         │
    2378 │ func apply(f: func(i32, i32) -> i32) -> i32 { f({ a: 1, b: 2 }) }
         │                                               ^^^^^^^^^^^^^^^^^
    ```
  ],
  caption: [A call by name needs a declaration. A function reference has only a type, and a type has no parameter names. The test appends its source to the standard library, hence the line numbers.],
) <fig:named-reference>

Named arguments also separate the order of evaluation from the order of parameters. Expressions are evaluated from left to right, as written at the call site, even when the names appear in a different order from the declaration. The resulting values are then arranged into parameter order. For example:

```wx
struct Point(x: i32, y: i32);

Point({
    y: compute_y(),
    x: compute_x(),
})
```

This is equivalent, in evaluation order and result, to:

```wx
local y = compute_y();
local x = compute_x();
Point(x, y)
```

Here, `compute_y` runs before `compute_x`, which matters if either call has side effects. The resulting `Point` still has its fields in declaration order, `(x, y)`. The same rule applies to named function arguments. The compiler may optimize the evaluation, but only when doing so preserves observable behavior.

A pattern takes a struct apart with the same syntax that builds it: `local Point(a, b) = p;` or `local Point({ x, y: py }) = p;`. WX has no positional field access like Rust's `t.0`. A tuple is taken apart by a pattern, and a struct field is read by its name.

== Function representation and ABI <sec:calls-abi>

Treating `func(A, B)` and `func((A, B))` as one type is only correct if both compile to the same WebAssembly function type. They do. A function's WebAssembly parameters are the stack representation of its `Args` (@sec:stack-repr), and its results are the representation of its `Result` (@tbl:call-abi).

#figure(
  booktable(
    columns: (auto, auto),
    align: (left, left),
    table.header([WX function], [WebAssembly type]),
    table.hline(stroke: 0.5pt),
    [`func add(a: i32, b: i32) -> i32`],
    [`(param i32 i32) (result i32)`],
    [`func g(p: (i32, i32)) -> i32`],
    [`(param i32 i32) (result i32)`],
    [`func divmod(a: i32, b: i32) -> (i32, i32)`],
    [`(param i32 i32) (result i32 i32)`],
    [`func shift(p: Point, d: u8) -> Point`],
    [`(param i32 i32 i32) (result i32 i32)`],
    [`func reset()`],
    [`(param) (result)`],
  ),
  caption: [The WebAssembly type of a WX function is the stack representation of its `Args` and `Result`.],
) <tbl:call-abi>

A function that returns several values uses multi-value, with no hidden pointer for the result. A struct passed or returned by value is flattened into its fields in declaration order, following `StackValue::Repr` (@sec:stack-repr). Its layout in linear memory is independent of this order. For example, `func(u8, u64)` becomes `(param i32 i64)`, regardless of how these types would be arranged in memory.

For imported and exported functions, this representation determines the exact sequence of WebAssembly parameter and result types exposed to the host. It remains stable regardless of memory layout optimizations or the order of named arguments at a call site. Internal functions may undergo transformations such as inlining or removal of unused parameters, provided their observable behavior is preserved. Functions at the module boundary, however, must retain their declared signatures. This lets WX optimize its internal code without changing the interface seen by the host.

`Repr` defines the core WebAssembly calling representation, rather than a complete cross-language ABI. Types with the same representation may still carry different meanings: `(u32, i32)` and `(i32, u32)` both become `(i32, i32)`. The host must therefore agree on the meaning and order of the values, not only their WebAssembly types.

== Comparison <sec:calls-comparison>

#figure(
  booktable(
    columns: (auto, 1fr, 1fr, 1fr),
    align: (left, left, left, left),
    table.header([Language], [Arguments as one value], [One-element tuple], [Named arguments]),
    table.hline(stroke: 0.5pt),
    [Standard ML],
    [yes],
    [none],
    [no; a record is passed instead],
    [Rust],
    [only in the `Fn` traits],
    [`(T,)`, different from `T`],
    [no],
    [Swift],
    [removed (SE-0029); function types kept apart (SE-0110)],
    [none],
    [yes, part of the function's name],
    [Python],
    [no],
    [`(x,)`],
    [yes, can be mixed with positional ones],
    [Kotlin],
    [no],
    [no tuples],
    [yes, can be mixed with positional ones],
    [WX],
    [yes],
    [none: `(T,)` is `T`],
    [yes, from the declaration, never mixed, not in types],
  ),
  caption: [How arguments are passed in WX and in five other languages.],
) <tbl:calls-comparison>

The rows follow the definition of Standard ML #fnote("milner1997"), the Rust documentation of the `Fn` traits #fnote("rust-fn-traits") and of tuple types #fnote("rust-tuples"), the Swift book #fnote("swift-functions"), and the Python #fnote("python-functions")#super[,]#fnote("python-tuples") and Kotlin #fnote("kotlin-functions") documentation.

Standard ML is the source of the one-value rule: a function takes one argument, and a function of several parameters takes a tuple. WX keeps this rule and adds argument names.

Swift tried the same idea and removed it. Early Swift allowed a function of several parameters to be called with one tuple. SE-0029 removed this "tuple splat" #fnote("swift-se0029"), among other reasons because the labels of the tuple had to agree with those of the function. SE-0110 then made a function of several parameters and a function of one tuple different types #fnote("swift-se0110")\; an exception that keeps closures convenient was added later. In WX, names are never part of a type, so this conflict cannot happen.

// Open point (2026-10-30): a struct constructor is not a first-class value yet (`compose(divmod, Point, ..)` is
// rejected, E2110). It may become a function item later.
