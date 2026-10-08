# Feature probes

Each probe asks one question: *can the developer cause this WebAssembly feature to appear in the module, and how?* Acceptance
is checked on the compiled `.wasm`, never on the source (see `README.md` §9). The feature list is `check/feature-list.mjs`; it is
ordered by **stabilisation**: module core first, the most recently standardised extensions last. The order is the spec version the
feature belongs to (1.0, 2.0, 3.0, from `WebAssembly/proposals/finished-proposals.md`), and within a version the order in which the
feature was first available in a major engine. The within-version order is approximate and has not been checked against the CG
meeting notes.

Terms: "the module" is the final artifact the build produces. Every probe exports functions with **fixed names** (below) so
that one checker can drive every language. Where a task says "export `f(i32) -> i32`", the Wasm types, not the source types,
are what is checked. A probe *passes* when every non-informational check holds; a failing probe is not an error, it is a
result, and the failing checks say which part is missing.

Probes live in `probes/<NN>-<slug>/<lang>/<variant>/`. A *variant* is a different way of attempting the same task in the same
language (a flag, an attribute, a nightly feature, inline assembly). A feature the language has no way to attempt has no
variant directory; it has an `ABSENT.md` in `probes/<NN>-<slug>/<lang>/` saying what was checked.

**Status.** All 30 features have a checker function, a reference module (checked by `make check-references`) and a probe or an
`ABSENT.md` in every one of the eight columns. Features 04, 13, 16, 19, 21, 22, 24, 28 and 30 were added after the first 21 had been
run; they are described in the second half of the criteria below. A feature that is specified but not yet probed would be `Pending`
in `results/coding.json` and left out of every mean in the rating (rather than scored as 0).

## The features

| # | Spec | Feature | Task for the program | Status |
|---|---|---|---|---|
| 01 | 1.0 | Imports and exports | Import `host.log(i32)`, export `run()` which calls it with 42 | probed |
| 02 | 1.0 | Memory | One memory, minimum 1 page, maximum 4. Two variants, scored separately: **export** (defined by the module, exported as `mem`) and **import** (imported as `host.mem`) | probed |
| 03 | 1.0 | Table and indirect call | Two functions reachable through a function-pointer table; export `call_slot(slot, x)` which calls slot 0 (`x*2`) or slot 1 (`x+100`) | probed |
| 04 | 1.0 | Table import and export | A funcref table, minimum 2, maximum 8. Two variants, scored separately: **export** (defined by the module, exported as `tbl`) and **import** (imported as `host.tbl`); in both, slot 0 holds a function doubling its argument and `call_slot(slot, x)` calls through the table | probed |
| 05 | 1.0 | Start function | A function runs before any export is called and sets a global to 7; export `get()` returns it | probed |
| 06 | 1.0 | Data segments | The bytes `WASM` are initialised data at linear-memory address **1024**; export `peek(addr) -> i32` reads one byte | probed |
| 07 | 1.0 | Custom sections | A custom section named `meta` containing the bytes `hello` | probed |
| 08 | 1.0 | Integer operations | Export `i_add i_sub i_mul i_div i_rem i_clz i_ctz i_popcnt i_rotl i_rotr` on i32 | probed |
| 09 | 1.0 | Float builtins | Export `f_sqrt f_min f_max f_ceil f_floor f_trunc f_nearest f_copysign f_abs` on f64 | probed |
| 10 | 1.0 | Globals | An exported mutable i32 global `counter`; an imported immutable i32 global `host.base`; export `bump()` that sets `counter = base + 1` and returns it | probed |
| 11 | 2.0 | Non-trapping conversions, sign extension | Export `sat_trunc(f64) -> i32` (saturating), `ext8(i32)`, `ext16(i32)` (sign-extend the low 8 / 16 bits) | probed |
| 12 | 2.0 | Bulk memory | Export `bulk_test(n)`: fill `n` bytes with 5, copy them elsewhere, return the sum of the copy (`n` is a run-time argument so a compiler cannot turn a small constant fill into plain stores) | probed |
| 13 | 2.0 | Passive data segments | Bytes `WASM` in a data segment that is not copied at instantiation; export `load(dst)` copies them to `dst` on request and releases the segment; export `peek(addr) -> i32` reads one byte | probed |
| 14 | 2.0 | Multi-value | Export `divmod(i32, i32) -> (i32, i32)` | probed |
| 15 | 2.0 | SIMD | Export `simd_add(a, b)` (splat both, add lane-wise, extract lane 0) and `simd_shuffle(a, b)` (splat both, shuffle with a mask mixing the two vectors, extract lane 0) | probed |
| 16 | 2.0 | SIMD memory and bitwise operations | Export `v_copy(p)`, `v_select(p)`, `v_narrow(p)`: vector load and store, bitwise select, and saturating narrowing, all working on vectors read from linear memory | probed |
| 17 | 2.0 | `externref` | Export `identity(externref) -> externref` | probed |
| 18 | 2.0 | Multiple tables | Two function tables; export `call_a(x)` (calls `x+1` through table A) and `call_b(x)` (calls `x+100` through table B) | probed |
| 19 | 2.0 | Table operations on references | Export `table_ops(n)`: grow a funcref table by `n`, store a function in one slot, read slots back, test them for null, and report the size | probed |
| 20 | 3.0 | Tail calls | Export `count(n, acc)` implemented as mutual recursion between two functions that tail-call each other; it must survive `n = 1,000,000` | probed |
| 21 | 3.0 | Extended constant expressions | A defined global whose initial value is computed from an imported global with integer arithmetic; export `get_g()` | probed |
| 22 | 3.0 | Typed function references | Export `apply(x)`: call a function through a typed function reference (`ref.func` then `call_ref`), with no table involved | probed |
| 23 | 3.0 | GC structs and arrays | Export `gc_test()`: build a struct with two i32 fields (2, 3) and an i32 array of length 4 with element 0 set to 10; return the sum (15) | probed |
| 24 | 3.0 | GC casts, subtyping, i31, packed fields | Export `gc_extra()`: a struct subtype upcast and cast back down, an `i31` value, and an array of packed 8-bit elements | probed |
| 25 | 3.0 | Multiple memories | Two memories; copy 4 bytes from one to the other with a single `memory.copy`; export `copy_test()` | probed |
| 26 | 3.0 | Relaxed SIMD | Export `relaxed_madd(a, b, c) -> f32` using a relaxed fused multiply-add on splatted operands | probed |
| 27 | 3.0 | Exception tags | Export `roundtrip(x)`: throw `x` as an exception and catch it, returning it | probed |
| 28 | 3.0 | Exception handling with exnref | Export `rethrow_test(x)`: throw `x`, catch it capturing the exception as a value, throw that value again, catch it outside and return `x` | probed |
| 29 | 3.0 | 64-bit memory | A memory with a 64-bit index; export `touch()` stores 42 at address 16 and returns the loaded value | probed |
| 30 | 3.0 | Branch hinting | Export `classify(x)`: a branch that is rarely taken is marked as unlikely in the source | probed |

## Acceptance criteria

The authoritative definition is `check/features.mjs`; this is its summary. "Emitted" means the instruction appears in the text
of the module (`wasm-tools print`) inside the exported function or any function it calls. Every probe also records, as an
informational check, whether the module validates with all extensions enabled, and whether the host had to call `_initialize`
(reactor) or `_start` (WASI command) before the exports worked.

### Probed features

- **01** Import `host.log` of type `(i32) -> ()`; export `run: () -> ()`; calling `run` makes the host see `42`.
- **02** Exactly one memory with limits min 1, max 4. *export*: defined in the module and exported as `mem`. *import*: imported
  as `host.mem`. The two are scored independently.
- **03** A funcref table, an element segment and a `call_indirect`; `call_slot(0,5) == 10`, `call_slot(1,5) == 105`.
- **05** A start section referencing a function; `get() == 7` on the first call (after the host has done whatever the module's
  own convention asks).
- **06** After applying the active data segments of memory 0, the bytes at 1024..1027 are `WASM`; `peek(1024) == 0x57` and
  `peek(1027) == 0x4d`.
- **07** A custom section `meta` whose payload is exactly `hello`.
- **08 / 09** For every member: the export exists, the matching opcode is emitted (`i32.add`, `i32.div_s|u`, `i32.clz`,
  `i32.rotl`, ..., `f64.sqrt`, `f64.min`, `f64.nearest`, `f64.copysign`, ...) and the function returns the expected value. The
  per-member results go to `members` in the verdict.
- **10** An exported mutable i32 global `counter`; an imported immutable i32 global `host.base`; `bump()` returns `base + 1` and
  `counter` holds the same value.
- **11** `i32.trunc_sat_f64_*`, `i32.extend8_s`, `i32.extend16_s` emitted; `sat_trunc(1e20)` is `i32::MAX`, `sat_trunc(-1e20)`
  is `i32::MIN`, `sat_trunc(NaN) == 0`, `ext8(0x80) == -128`, `ext16(0x8000) == -32768`.
- **12** `memory.fill` and `memory.copy` emitted; `bulk_test(8) == 40`, `bulk_test(40) == 200`. If `array.fill`/`array.copy` are
  used instead (the GC-array equivalents) that is recorded informationally.
- **14** `divmod` has two results (not one result plus an out-pointer) and `divmod(17,5) == [3,2]`.
- **15** `i32x4.splat`, `i32x4.add`, `i32x4.extract_lane` emitted in `simd_add`; `i8x16.shuffle` emitted in `simd_shuffle`;
  `simd_add(2,3) == 5`, `simd_shuffle(1,2) == 2`.
- **17** `identity: (externref) -> externref`; the host's object comes back identical.
- **18** Two or more tables; `call_indirect` uses two different tables; `call_a(5) == 6`, `call_b(5) == 105`. (Element segments
  are recorded but not required: a table may be filled with `table.set` at run time.)
- **20** `return_call` (or `return_call_indirect`) emitted *and* `count(1000000, 0) == 1000000` without exhausting the stack.
  The two are reported separately: a compiler may turn the recursion into a loop (no opcode, still works) or emit the opcode in
  one direction only (opcode, still overflows).
- **23** The module defines a struct type and an array type, `struct.new`/`struct.get` and `array.new*`/`array.get` appear
  somewhere in it, and `gc_test() == 15`. Use of typed function references (`call_ref`, `ref.func`) is recorded
  informationally here and scored on its own by feature 22.
- **25** Two or more memories; a `memory.copy` whose two memory operands differ; `copy_test() == 10`.
- **26** `f32x4.relaxed_madd` (or `relaxed_nmadd`) emitted; `relaxed_madd(2,3,4) == 10`.
- **27** A tag section with at least one tag; exception-handling instructions present; `roundtrip(5) == 5`. The tag's payload
  type is recorded informationally (the reference module uses i32; C++ and Kotlin use other representations). The checker
  accepts either encoding (legacy `try`/`catch` or `try_table`) and does not record which one was used; feature 28 asks for the
  standardised form specifically.
- **29** A memory whose index type is 64-bit; `touch() == 42`.

### Added after the first 21 were probed

Each has a `reference.wat` (or `reference.export.wat` / `reference.import.wat`) that satisfies the criteria, a checker function in
`check/features.mjs`, and a variant per language or an `ABSENT.md`. They are separate features, not extra members of an existing
family, so that the verdicts of the probes already run stay valid.

- **04 Table import and export.** Two variants, scored independently, as for 02.
  *export*: a funcref table with limits min 2, max 8, defined in the module and exported as `tbl`; slot 0 holds a function
  returning `x*2`; the host reads `tbl.get(0)` and calls it: `tbl.get(0)(5) == 10`. *import*: the table is imported as
  `host.tbl` with the same limits, an active element segment puts the doubling function into slot 0, and `call_slot(0,5) == 10`
  through a `call_indirect` on the imported table. Informational: whether the table's name and the import's module and field
  can be chosen in the source or only by a linker option.
  *Why it is its own feature:* 02 covers memory only; a table is exposed to the host in the same way, and a language can
  support one without the other.
- **13 Passive data segments.** A data segment in passive mode (not applied at instantiation) holding `WASM`; `load(dst)` applies
  it with `memory.init` at a run-time `dst` and then drops it with `data.drop`; `peek(dst) == 0x57` and `peek(dst+3) == 0x4d`
  after `load(2048)`, and `peek(2048) == 0` before. Required: a passive segment in the module, `memory.init` emitted. Recorded
  informationally: `data.drop` emitted.
  *Why it is its own feature:* 06 covers active segments only, and a compiler that places data at a fixed address says nothing
  about whether the developer can request a segment that is copied on demand (the mechanism behind lazy initialisation and
  shared-memory builds).
- **16 SIMD memory and bitwise operations.** The host writes test data into the first exported memory, then calls three
  exports that each take a base address `p`.
  `v_copy(p)`: `v128.load` from `p`, `v128.store` to `p+16`; returns the byte at `p+16`.
  `v_select(p)`: loads vectors `a`, `b` and a mask from `p`, `p+16`, `p+32`, stores `v128.bitselect(a, b, mask)` at `p+48`,
  returns the first i32 of the result.
  `v_narrow(p)`: loads two `i16x8` from `p`, `p+16`, applies `i8x16.narrow_i16x8_s`, stores at `p+32`, returns the first byte.
  Required per member: the opcode emitted (`v128.load`, `v128.store`, `v128.bitselect`, `i8x16.narrow_i16x8_s`) and the stored
  result equals the expected bytes. Reported per member, as for 08 and 09. Vectors come from memory so the optimiser cannot fold
  them into scalar code (see the SIMD note in `README.md`).
  *Why it is its own feature:* 15 samples lane arithmetic, splat/extract and one shuffle; a language can expose those and still
  have no way to load, store or select vectors, which is most of what SIMD code does.
- **19 Table operations on references.** `table_ops(3)`: a funcref table of initial size 1 grows by 3 with `table.grow`, slot 1
  is set to a function with `table.set`, and the function returns
  `table.size + (ref.is_null(table.get(2)) ? 100 : 0) + (ref.is_null(table.get(1)) ? 0 : 1000)`, which is `1104`.
  Required: `table.grow`, `table.set`, `table.get`, `table.size`, `ref.is_null` emitted; `table_ops(3) == 1104`.
  *Why it is its own feature:* 17 passes an `externref` through and 18 needs two tables, but neither requires the developer to
  operate on a table at run time, which is what the reference-types proposal added.
- **21 Extended constant expressions.** A module imports an immutable i32 global `host.base` and defines a global `g` whose
  initialiser is `base + 4 * 3`. Required: the global section's initialiser for `g` is a constant expression containing
  `global.get` and at least one of `i32.add`/`i32.mul` (not a plain constant and not a start function that computes it); the host
  gives `base = 100`, and `get_g() == 112`. Recorded informationally: whether the module computed the value in a start function
  instead.
  *Why it is its own feature:* the earlier plan folded this into 10 Globals; that probe only needs a plain initial value, so it
  cannot tell a compiler that evaluates `base + 12` in the module's global initialiser from one that does it at start-up.
- **22 Typed function references.** `apply(5) == 10`, where `apply` takes the address of a function that doubles its argument as
  a typed reference (`ref.func`) and calls it with `call_ref`. Required: `call_ref` emitted in `apply` and `ref.func` emitted anywhere in the module (the reference may be built in an initialiser), `apply(5) == 10`.
  Recorded informationally: the reference type is non-nullable (`(ref $t)`), `ref.as_non_null` or `br_on_null` emitted, and
  whether any `call_indirect` or table is also present.
  *Why it is its own feature:* the two Wasm GC languages (MoonBit wasm-gc, Kotlin) call function values with `call_ref`, so 03
  scores them Absent for a mechanism they do not use. This feature credits the mechanism they do use, and for linear-memory
  languages it measures whether function values can avoid a table.
- **24 GC casts, subtyping, i31, packed fields.** `gc_extra() == 210`: a struct type `Animal { i32 }` with a declared subtype
  `Dog { i32, i32 }` (extra field `3`) is built as a `Dog` and held as an `Animal`; `ref.test` or `ref.cast` recovers the `Dog`
  and reads the extra field (3); `ref.i31` wraps `7` and `i31.get_s` reads it back; an array of packed 8-bit elements is created
  with element 0 set to `200` and read with `array.get_u`. The sum is `3 + 7 + 200`. Reported per member, as for 08 and 09:
  declared subtype (`sub`), `ref.test`/`ref.cast`, `ref.i31` + `i31.get_*`, packed array element (`i8`) with `array.get_s|u`.
  *Why it is its own feature:* 23 needs only `struct.new` and `array.new`, which any GC-backed object model produces; whether a
  language can express casts, subtyping and packed storage separates a thin wrapper over structs from a real mapping of the
  language's types onto the GC proposal.
- **28 Exception handling with exnref.** `rethrow_test(5) == 5`: a tag carrying an i32 is thrown; a `try_table` with a
  `catch_ref` (or `catch_all_ref`) clause captures the exception as an `exnref`; `throw_ref` throws it again; an outer handler
  catches it and returns `5`. Required: a tag, `try_table` and `throw_ref` emitted; the result is correct. The legacy
  `try`/`catch`/`rethrow` encoding does not pass here (it is recorded). Recorded informationally: which clause kinds were used.
  *Why it is its own feature:* 27 accepts either encoding. The standardised encoding is the one in the spec, the legacy one is
  listed as inactive, and C++ shows both can coexist in one toolchain with only one working.
- **30 Branch hinting.** `classify(x)` returns `-1` for `x < 0` (the rare branch, marked unlikely in the source) and `x*2`
  otherwise. Required: a custom section `metadata.code.branch_hint` with at least one hint whose function is `classify`
  (the hint values, 0 unlikely and 1 likely, are recorded and not required, because the checker does not map byte offsets back to
  branches); `classify(5) == 10`, `classify(-1) == -1`. The probe records the outcome
  whatever it is: a language whose toolchain never emits this section gets `Absent`, and the variants tried (an attribute, an
  intrinsic such as `likely`/`unlikely`, an optimisation flag) are the evidence.
  *Why it is its own feature:* it is a standardised extension with no other probe covering it, and it is a pure test of whether
  a source-level hint survives into the binary.

### Left out on purpose

Threads and atomics and wide arithmetic (phase 4, not in a released spec version), stack switching and custom page sizes (phase 3),
the Component Model, JS string builtins and JS BigInt integration (JS-host APIs that do not change the module), custom annotation
syntax (text format only, no effect on the binary), and the deterministic profile (an execution-environment restriction).

## Why some probes have several variants

The task is fixed; the *attempts* differ. Examples of what a variant is: Rust's `stable` vs `nightly-asm` vs `nightly-become`;
a flag such as `--global-base=1024` or `-mbulk-memory`; an inline-assembly attempt next to a library attempt; a "vectors from
memory" version of the SIMD probe next to the plain one (because LLVM folds `extract(splat+splat)` back to a scalar add).
The matrix cell for a language takes the best result *a developer could reasonably reach*, and the variants that fell short
are the evidence for the flag attached to it.
