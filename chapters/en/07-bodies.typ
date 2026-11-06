#import "../../template.typ": booktable, muted, todo
#import "../../bibliography.typ": fnote

= Function Bodies: Expressions on the Stack <ch:bodies>

Function bodies connect the entities, values, calls and instructions described in the preceding chapters. WebAssembly is an operand-stack machine with structured control flow: instructions consume stack operands, and loops and conditionals are nested constructs. WX follows Rust's expression-oriented syntax. The discussion focuses on its WebAssembly representation and on rules that differ from Rust.

== A body is an expression <sec:body-stack-machine>

Each WebAssembly instruction pops its operands from the stack and pushes its results #fnote("wasm-spec-exec-instructions"), and no instruction names a variable for an intermediate value:

```wat
(func $area (param $w i32) (param $h i32) (result i32)
  local.get $w     ;; stack: w
  local.get $h     ;; stack: w h
  i32.mul          ;; stack: (w*h)
  i32.const 1      ;; stack: (w*h) 1
  i32.add)         ;; stack: (w*h)+1
```

A language can hide this behind statements and variables, as C does, or make every construct produce a value, so that the result of one is the operand of the next. WX does the second. A body is an expression, and its last expression is the function's result:

```wx
func area(w: u32, h: u32) -> u32 {
    w * h + 1
}
```

This compiles to the sequence above, with no `return` and no variable. An expression's type determines its stack representation through `StackValue::Repr` (@sec:stack-repr): a `u32` leaves one `i32`, `()` leaves nothing, and a struct leaves the flattened representations of its fields. WebAssembly validates the function's result stack against its declared result types. WX checks that the body's final expression has the declared WX result type, which also determines that stack representation.

== Blocks, statements and multiple values <sec:body-blocks>

A block `{ ... }` is statements followed by an optional final expression, which is the block's value. A statement ends in `;` and leaves nothing on the stack, so its expression must have the type `()` or `!`. This differs from Rust, where `;` discards a value. In WebAssembly a value that nothing consumes makes the function invalid, and `drop` is how a program says it does not want one. WX has the same rule in the source: `g();` for a `g` returning `u32` is an error (E2003, "value must be used"), and the program writes the drop where it happens:

```wx
_ = g();       // evaluates g, drops its u32
```

A result that is easy to ignore by accident, such as the status code of a WASI call, is therefore ignored only by a line that says so.

An `if` without `else` leaves nothing when its condition is false, so its type is `()`. An `if` with both branches must have branches of one type, so the stack has the same shape on either path, as validation requires of `if ... else ... end` (@lst:body-errors).

#figure(
  ```wx
  func f() -> i32 { local x: i32 = 1; }
  // error[E2001]: type mismatch (the body is `()`, not `i32`)

  func g(c: Bool) -> i32 { if c { 1 } }
  // error[E2052]: `if` may be missing an `else` clause
  ```,
  caption: [Two bodies that would leave the wrong values on the stack. The messages are the compiler's, shortened.],
) <lst:body-errors>

A function may return several values, and an expression of a tuple or struct type leaves several, so multi-value needs no special syntax:

```wx
func divmod(a: u32, b: u32) -> (u32, u32) {
    (a / b, a % b)
}

func quotient_plus_rest(a: u32, b: u32) -> u32 {
    local (q, r) = divmod(a, b);
    q + r
}
```

`divmod` has the Wasm type `(i32 i32) -> (i32 i32)`. The caller takes the pair apart with a destructuring `local`, the only way to take a tuple apart, since WX has no positional field access.

== Control flow keeps the structure of WebAssembly <sec:body-control>

*Structured* control flow means that a branch can only go to a construct that encloses it: there is no `goto` and no way to enter a loop in the middle. The nesting of the source is therefore the nesting of the module. The compiler needs no control-flow analysis to know a branch is valid, because a `break` is valid when its label names an enclosing `block` or `loop` (E2012 when none does).

WebAssembly has three constructs, `block`, `loop` and `if`, and a branch `br n` leaves the enclosing construct `n` levels up #fnote("wasm-spec-modules"). Leaving a `block` or `if` continues after its `end`, leaving a `loop` continues at its start, and a branch can carry values that become the result of the construct. The number `n` is the kind of entity index that @sec:identity-shape set out to remove: it changes when a construct is added around the branch, and nothing in the instruction says what it is for. WX never writes it. A branch names its target and the compiler computes the depth (@tbl:control-flow).

#figure(
  booktable(
    columns: (auto, auto),
    align: (left, left),
    table.header([WX], [WebAssembly]),
    table.hline(stroke: 0.5pt),
    [`if c { a } else { b }`],
    [`if` … `else` … `end`],
    [`block :l { ... }`],
    [`block` … `end`],
    [`loop { ... }`],
    [`block` containing a `loop`],
    [`break :l value`],
    [`br` to the end of the construct `:l`, carrying `value`],
    [`continue :l`],
    [`br` to the start of the loop `:l`],
    [`return value`],
    [`return`],
    [`match x { ... }`],
    [nested `block`s and `br_table` for a dense set of integers, otherwise an `if` chain],
  ),
  caption: [Control flow in WX and the WebAssembly construct each form is compiled to.],
) <tbl:control-flow>

A `loop` is a `block` around a `loop` because a WebAssembly `loop` can only be re-entered: a branch to it goes back to its start, and nothing leaves it forward. The outer `block` is where `break` goes. Both belong to the one WX expression, whose value is given by its `break`s:

```wx
func first_multiple(n: u32, of: u32) -> u32 {
    local mut i: u32 = 1;
    loop {
        if i * of >= n { break i * of };
        i += 1;
    }
}
```

```wat
block                      ;; the target of `break`
  loop                     ;; the target of `continue`
    ...
    if
      ...                  ;; the value of `i * of`
      br 2                 ;; `break`: out of the `if` and the `loop`
    end
    ... i += 1 ...
    br 0                   ;; back to the start of the `loop`
  end
end
```

A label lets a `break` or `continue` leave a loop other than the innermost, and a labelled `block` gives code that is not a loop the same early exit. Substring search needs it: one loop runs over the positions in the text, an inner one compares the bytes at a position, and a match found in the inner loop ends the outer one (@lst:body-search).

#figure(
  ```wx
  func find<Mem: Memory>(
      text: Mem::&[u8],
      pattern: Mem::&[u8],
  ) -> (Bool, Mem::Size) {
      local mut start: Mem::Size = 0;
      loop :outer {
          if start + pattern.len() > text.len() {
              break :outer (False, 0)
          };
          local mut k: Mem::Size = 0;
          loop {
              if k == pattern.len() { break :outer (True, start) };
              if text[start + k] != pattern[k] {
                  start += 1;
                  continue :outer
              };
              k += 1;
          }
      }
  }
  ```,
  caption: [Naive substring search, generic over the memory (`examples/search`). `break :outer` leaves both loops with the result, and `continue :outer` abandons the inner loop and moves to the next position.],
) <lst:body-search>

The three exits leave different numbers of constructs: in the compiled module `break :outer` is `br 2` in the outer loop and `br 4` in the inner one, and `continue :outer` is `br 3`. The source writes none of them. Positions and lengths have the memory's own address type, so one definition searches a 32-bit and a 64-bit memory. Since that type is not known, there is no sentinel such as `u32::MAX` for "not found", and the result carries a flag: the pair `(Bool, Mem::Size)` stands in for an `Option<Mem::Size>`, because WX has no sum types yet. They are a planned feature, and the position in the pair is meaningful only when the flag is `True`. A module exports an instance of the function for one memory, because an export cannot be generic.

== Code that does not continue: the type `!` <sec:body-never>

WX's `!` is Rust's never type: `return`, `break`, `continue`, `trap()` and a `loop` with no `break` have it, and it coerces to any type. WebAssembly needs the same idea for validation. After `br`, `return` or `unreachable` the stack is *polymorphic*: the code that follows is checked as if the stack held whatever it needs, because it can never run #fnote("wasm-spec-modules"). `!` is the type-level form of that rule, so the checker accepts what validation accepts, for the same reason. `if x == 0 { trap() } else { x - 1 }` has type `u32`, and its `trap()` branch compiles to `unreachable`.

== Locals and patterns <sec:body-locals>

A WebAssembly function has numbered, typed locals, read and written by `local.get`, `local.set` and `local.tee`. A WX parameter is a local, and `local` declares another, immutable unless marked `mut`. Unlike a C variable, a local has no address: WebAssembly cannot point at one, so `.&` applies only to places in a memory (@sec:memory-access), and a structure that needs an address is allocated in a memory on purpose.

`local` and `match` take the same patterns, as in Rust: names, `_`, tuples and structs, nested. One exhaustiveness check serves both, and a missing case is reported with an example (E2066, "pattern `Dir::Down` not covered"). A destructuring `local` must be exhaustive, and `..` relaxes that.

== Types are decided by the statement <sec:body-inference>

Every WebAssembly instruction has a fixed type: `i32.add` adds `i32` and `f32.add` adds `f32`, and no instruction adds "numbers". A rule for guessing a type is therefore a rule for choosing an instruction, and WX keeps both explicit. There are no implicit conversions: adding a `u8` to a `u32` is a type mismatch (E2001), even though both are held as an `i32`, and a change of type is written where it happens, with `transmute` between types of the same representation (@sec:transmute) or a named instruction such as `i64_extend_i32` (@sec:intrinsic-functions).

A literal such as `5` has the type `{integer}`: an integer whose width and signedness are not decided yet. It exists only at compile time, because WebAssembly has no such value (`i32.const 5` and `i64.const 5` are different instructions), and `{integer}` is not a `StackValue` (@sec:stack-repr), so nothing can hold it on the stack. A literal therefore takes a concrete type from its context, and where the context gives none there is no default. A local needs a `StackValue`, so `local c = 5` has nothing to store. A constant, which is evaluated at compile time and never stored, can keep the type: `const X: {integer} = 4` is given a type at each use.

```wx
local a: u8 = 5;        // from the annotation
local b = (5: u8);      // from the ascription
local c = 5;            // error[E2002]: type annotation required
```

Inside one expression, type information flows in both directions, as in bidirectional type checking #fnote("dunfield2021"). It flows *down* from the expected type: in `func f() -> u8 { id(5) }` the result type fixes the type argument of `id<T>`, and that in turn fixes the literal. It flows *up* from operands: in `x + 1` with `x: u8` the literal takes the type of its other operand, and in `id(x)` the argument tells the call what `T` is. A call's type arguments are learned in that order, from the expected type and then from the arguments, and one still unknown when the expression ends is an error (E2002 on `T` for `make()` with `func make<T>() -> T`).

The flow stops where the expression is bound to a local. The local has the type its initializer was given, and a later use never reaches back: `local y = id(5); y` in a function returning `u8` is rejected, although `y` is returned as a `u8` on the next line, while `local y = (id(5): u8)` is accepted.

== Comparison <sec:body-comparison>

Expression-oriented blocks, `loop` with `break value` and labelled blocks exist in Rust, and Zig has labelled blocks that break with a value. C and AssemblyScript use statements and need a variable or a conditional operator to carry a value out of a branch. Inference is also narrower than in ML-family languages: with Hindley–Milner inference #fnote("damas1982") a later use can decide the type of an earlier local, while in WX it stops where an expression is bound to a local, and in exchange a reader never needs to look forward to know which instruction a line becomes. What WX adds is a reading of the platform, not a new construct: the last expression is the stack at the end of the function, a named branch replaces a depth, `!` is the polymorphic stack, `;` leaves nothing so a drop is explicit, and typed instructions mean literals have no default.
