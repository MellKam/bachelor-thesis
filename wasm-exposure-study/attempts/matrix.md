# Results matrix (preliminary)

Compiled by hand from `attempts/<lang>.md` on 2026-10-02; the per-language files hold the evidence and caveats. Codes: README §6
(**N** native, **A** annotation, **C** build config, **E** escape hatch, **X** not achievable, **\*** partial, **‡** needs nightly,
"unresolved" = no way found, not proven impossible). "(table implicit)" = the construct appears but cannot be named or sized.
P11 is supplementary. Sizes are release builds only.

| Probe | Rust 1.99.0 | Zig 0.16.0 | AssemblyScript 0.28.20 | Grain 0.7.2 | MoonBit (moon 0.1.20260920) |
|---|---|---|---|---|---|
| P1 imports/exports | A | N | A | N (raw `WasmI32` layer only) | N |
| P2 memory, export | C | C\* (name fixed) | C\* (name fixed) | C\* (name fixed) | C |
| P2 memory, import | C | C\* (name fixed) | C\* (name fixed) | C\* (name fixed) | C |
| P3 multi-memory | X | X | X | unresolved | unresolved |
| P4 globals | X; E‡ | X | N | X | X |
| P5 table + indirect call | N (table implicit) | N (table implicit) | N (table implicit) | N (table implicit) | N (table implicit) |
| P6 multi-value | X; E‡ | X | X | X | X |
| P7 start function | A\* (no start section) | A\* (no start section) | N | C | N |
| P8 externref | X; E‡ | X | N | unresolved | N |
| P9 exceptions (tags) | X; E‡ | X | X | X | X (works, no tags) |
| P10 popcnt / SIMD | N / E | N / N + C | E / E | E / unresolved | E / E |
| P11 custom section | A | X | unresolved | unresolved | unresolved |
| P12 release size (bytes) | 302 (`no_std`), 322 (std) | 73 (Small), 4,977 (Fast) | 55 | 3,650 | 188 |
| P12 unrequested surface | `memory` export; 16-page memory | `memory` export; table; stack-pointer global | `memory` export | `fd_write` import, `_start`, `memory`; 20 globals | none |

## Reading the hypotheses (README §5) against this table

- **H1** (memory is the least developer-controllable area): *supported in part.* In every language the memory is configured, never declared in
  source, and in four of five its exported and imported names cannot be chosen freely. MoonBit is the exception (full control through its
  build file). Rust lets you choose names too, through linker flags.
- **H2** (globals, tables and tags are rarely language constructs): *largely supported.* Only AssemblyScript has real globals (P4) and
  nobody has a table or tag construct; tables appear only as a side effect of function pointers.
- **H3** (multi-memory is not expressible in any subject): *supported, with a caveat.* Rust and Zig accept a memory index and Rust's
  nightly assembly accepts `memory.copy 1, 0`, but the linker produces a single memory and the module is invalid. For Grain and MoonBit
  I only found no option, which is weaker.
- **H4** (Wasm-first languages add more unrequested surface than LLVM-based ones): *not supported.* AssemblyScript (55 bytes) and MoonBit
  (188 bytes, no unrequested exports) are the smallest; only Grain is large (3,650 bytes).
- **H5** (the boundary is unchecked in every subject): *not measured by these probes.* They show boundary representation (raw values in
  Rust, Zig, AssemblyScript and MoonBit; Grain's tagged values), not what checking exists. Needs its own test or should be dropped.

## Capstones

See `attempts/capstones.md`: Game of Life and WASI `cat` were built in all five languages, raw builds only, and all passed.

## Not yet done

- The *idiomatic* capstone builds (README §7) and build-time / determinism metrics.
- The unresolved cells: each needs a deliberate attempt, or a maintainer/doc statement, before it can become X.
- Rust probes on `wasm32-wasip1` (the probes only used `wasm32-unknown-unknown`), MoonBit `wasm-gc`, and a determinism check (build twice, compare hashes).
