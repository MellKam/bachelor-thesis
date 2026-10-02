# wx — probe results (kept outside the Chapter 2 comparison)

Compiler: **wx 0.5.0**, the prebuilt binary `/home/melkam/wx/target/release/wx` (built 2026-09-11, i.e. after tag `v0.5.0` of
2026-09-05; exact commit unknown). The repository HEAD is mid-refactor and was deliberately **not** built or used. Unlike the other
five languages this runs on the host, not in a pinned container (`probes/run-wx.sh`), so it is **not reproducible** the way the
rest of the study is. Sources in `probes/<id>/wx/<variant>/`, logs in `results/wx/`. Release-size note: wx has no separate release
mode in this build; sizes are what `wx build` produced.

This column is **not** part of the Chapter 2 comparison. wx's author wrote both the language and these probes, so it belongs in the
evaluation chapter with that bias stated.

| Probe | Result | Summary |
|---|---|---|
| P1 imports/exports | **N** | `import "host" as host { fn log(x: i32); }` and an `export { run }` block |
| P2 memory export | **A** | `#[memory_limits(min_pages = 1, max_pages = 4)] memory heap: Memory where { Size = u32 };` and `export { heap as "mem" }` |
| P2 memory import | **X** (this build) | `import "host" as host { memory mem: u32; }` parses, but the memory cannot be referenced (`E1007 undeclared identifier`, `E1021 undeclared type`) and the import is dropped |
| P3 multi-memory | **N** | two `memory` declarations; `memory_copy::<u32, a, b>(dst, src, n)` is a valid `memory.copy` between them; checker passed incl. runtime copy |
| P4 globals | **N** | `global mut counter: i32`, `import … { global base: i32; }`, both exported/imported as real Wasm globals; `bump() == 42` |
| P5 table + indirect call | **N** (table implicit) | `local f = if … { double } else { plus100 }; f(x)` → table, element segment, `call_indirect` |
| P6 multi-value | **N** | `fn divmod(a: u32, b: u32) -> (u32, u32)` exports as `(i32, i32) -> (i32, i32)` |
| P7 start function | **X** | no start construct; global initialisers are constant-only by design; the helper `init` was never called and `get()` returned 0 |
| P8 externref | **X** | `E1021: undeclared type` for `externref` |
| P9 exception tags | **X** | `tag Boom(code: i32) -> !;` → `E0009: invalid item` (tags are designed, not in this build) |
| P10 raw instructions | **X** | `x.count_ones()` → `E1049: no method`; the `v0.5.0` standard library has no popcnt/clz-style names that I could find, and no SIMD (only `count_ones` was tried as source) |
| P11 custom section | **X**, silently | `#[link_section = "meta"]` is accepted with no effect (output is the same 41 bytes) |
| P12 baseline | measured | 41 bytes; no imports, no exports beyond `add`, **no memory unless one is declared** |

## Life capstone (same shared host, unchanged)

`capstones/life/wx/`: **506 bytes**, passes the 100-generation check, no extra imports or exports, no `_start`. It uses
`memory heap` with typed pointers, `at(grid, i) -> heap::*u8`, `loop`/`break`, and an exported memory. WASI `cat` was **not**
written for wx.

## What the tagged pointer type does and does not do

- A pointer type names its memory (`a::*u8`, `heap::*Node`). Passing a pointer into memory `b` where memory `a` is expected is a
  compile error (`E1001: expected b::*u8, found a::*u8`, tested with `memory_copy`). In the other five languages the pointer carries
  no memory at all.
- It does **not** remove integer-to-pointer arithmetic: in the Life program the grids are still hand-placed (`(grid * 4096 + i) as
  heap::*u8`), there is no bounds check, and a wrong offset is a silent error. The type prevents mixing memories, not bad addresses.
  (The language also has typed structs behind pointers and an `Allocator` trait with a bump allocator in `examples/`, which the
  probes did not exercise.)

## Caveats

- Version and reproducibility: see the top. Results at the refactored HEAD may differ, in either direction.
- Syntax was learned from the repository's examples and tests; an outside user would likely have needed more attempts.
- Several negative results are short, single attempts (P2 import, P10).
