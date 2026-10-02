# Probe specifications

Each probe asks one question: *can the developer cause this construct to appear in the
module, and how?* Acceptance is checked structurally on the compiled `.wasm` (see
`README.md` §9). Terms: "the module" is the final artifact the build produces. Proposal-stage
or recently standardised features are marked **(ext)**; for those the engine version must
support the feature or the result is recorded as "emitted, host rejects".

Feature status in the standard (which proposals are finished, which are in Wasm 3.0) is
**not asserted here** and must be taken from the spec and proposals repository at freeze time.

| ID | Concept | Entity / extension | Task for the program |
|---|---|---|---|
| P1 | Imports and exports, naming | functions, import/export sections | Import `host.log(i32)`, export `run()` which calls it with 42 |
| P2 | Memory configuration | memory section | Min 1 page, max 4 pages. Two variants, reported separately: **export** (memory defined by the module, exported as `mem`) and **import** (memory imported as `host.mem`) |
| P3 | Multiple memories **(ext)** | multi-memory | Two memories; copy N bytes from memory 0 to memory 1 |
| P4 | Globals | global section | Exported mutable i32 `counter`; imported immutable i32 `host.base` |
| P5 | Tables and indirect calls | table + element sections | Table of two functions; export `call_slot(i32, i32) -> i32` using `call_indirect` |
| P6 | Multi-value | type section | Export `divmod(i32, i32) -> (i32, i32)` |
| P7 | Start function | start section | Initialise a global before any export is called |
| P8 | Reference types | `externref` / `funcref` | Export `identity(externref) -> externref` |
| P9 | Exceptions **(ext)** | tag section, EH instructions | Throw with an i32 payload, catch and return it; compare with trap/abort |
| P10 | Raw instruction access | instruction set | Export `popcount(i32)` using `i32.popcnt`; export an `i32x4.add` wrapper |
| P11 | Custom sections *(supplementary)* | custom sections | Emit a custom section named `meta` |
| P12 | Unrequested surface | all | Program with a single export `add(i32, i32) -> i32` and nothing else |

## Acceptance criteria

All criteria are evaluated on the module bytes; "host" refers to the shared script.

- **P1** Import section has module `host`, field `log`, type `(i32) -> ()`. Export section has
  function `run` of type `() -> ()`. Instantiating with a `log` that records its argument and
  calling `run` records `42`.
- **P2** Exactly one memory in total, with limits min 1, max 4. Variant **export**: the module
  defines it and exports it as `mem`. Variant **import**: the module imports it as `host.mem`.
  The two variants are scored independently; a language may satisfy one and not the other.
- **P3** Memory index space has two entries; a `memory.copy` instruction whose two memory
  operands differ. After running, bytes written to memory 0 appear in memory 1.
- **P4** A global with `mut` flag exported as `counter`; an import `host.base` of global kind,
  type i32, immutable. A function reading `base` and writing `counter` returns the expected
  value.
- **P5** A table (funcref) with at least two elements, an element segment, and a
  `call_indirect` in `call_slot`. `call_slot(0,x)` and `call_slot(1,x)` call different
  functions.
- **P6** Type of `divmod` has two results (not one result plus pointer/out-parameter).
- **P7** Start section present and referencing a function, *or* a documented equivalent
  recorded as a partial result. Global holds the initialised value on first export call.
- **P8** Export `identity` with type `(externref) -> externref`; host passes an object and
  receives the identical object.
- **P9** Tag section with an i32-payload tag and use of exception-handling instructions; throw
  and catch observed in-module. Result is **N/A/E/...** by how it is written, not by what the
  engine does. If the language lowers errors to trap or abort instead, record that.
- **P10** The function body contains the target opcodes (`i32.popcnt`, `i32x4.add`) rather
  than a call to a helper that emulates them.
- **P11** *(supplementary)* A custom section named `meta` is present. Not part of the core matrix or the
  hypotheses in `README.md`; it records whether source code can emit tooling metadata.
- **P12** Not pass/fail. Record every import, export, memory, global, table, start function
  and custom section beyond `add`, plus byte size. This establishes the baseline for the
  hidden-surface metric.

## Naming conventions the checker relies on

Programs must use these export names so one checker serves every language. Behaviour is checked
by instantiating the module and calling the export (host-supplied imports are listed per probe).

| Probe | Exports / imports | Expected behaviour |
|---|---|---|
| P1 | import `host.log(i32)`; export `run()` | `run()` calls `log(42)` |
| P2:export | export memory `mem` (1..4 pages) | memory defined in the module, the only memory |
| P2:import | import memory `host.mem` (1..4 pages) | the only memory; the host supplies it |
| P3 | export `copy_test() -> i32` | writes bytes 1,2,3,4 to memory 0, copies them to memory 1, returns their sum read from memory 1 (10) |
| P4 | import global `host.base` (i32, immutable); export mutable global `counter`; export `bump() -> i32` | with `base = 41`, `bump()` sets `counter = base + 1` and returns 42 |
| P5 | export `call_slot(slot: i32, x: i32) -> i32` | slot 0 doubles `x`, slot 1 adds 100 (`call_slot(0,5)=10`, `call_slot(1,5)=105`) |
| P6 | export `divmod(a, b: i32) -> (i32, i32)` | unsigned quotient and remainder (`divmod(17,5)=[3,2]`) |
| P7 | export `get() -> i32` | returns 7, set by the start function before the first call |
| P8 | export `identity(externref) -> externref` | returns its argument |
| P9 | export `roundtrip(x: i32) -> i32` | throws `x` as an exception payload, catches it in-module, returns `x` |
| P10 | export `popcount(i32) -> i32`, `simd_add(a, b: i32) -> i32` | `popcount(255)=8`; `simd_add` splats both, `i32x4.add`, returns lane 0 (`simd_add(2,3)=5`) |
| P11 | none required | custom section `meta` present |
| P12 | export `add(i32, i32) -> i32` | `add(2,3)=5`; everything else is surplus |

P10's opcode check is approximate: it looks for the opcode anywhere in the module's text, not
only inside the named function, so a program that also uses it elsewhere would pass. Judge a
borderline case by reading the disassembly.

## Running the checker

```
node check/run.mjs <probe[:variant]> <module.wasm|module.wat> [--json]   # e.g. P2:import
node check/validate-references.mjs     # every probes/<id>/reference.wat must pass
```

Both run inside any language container (they need Node, `wat2wasm` and `wasm2wat`).

## Deliberately not probed: data segments

Data segments are in the spec's list of module entities, but every subject emits them
implicitly for string literals and static arrays, so a probe would mostly record "implicit".
Placing data at a chosen address (an earlier draft of P11) is something ordinary languages do
not expose and was dropped as uninformative. Initial data in a *second* memory is covered by
P3's multi-memory question.

## Notes on fairness

- A probe may be solved in any way the language documents; the outcome code records which.
- If a language targets several backends, the probe uses the one that meets the criteria most
  directly, and the choice is logged.
- Probes do **not** require the program to be pleasant, only for the construct to appear and
  work. How natural it feels is discussed in prose in the thesis, using the objective counts
  from `README.md` §8.
