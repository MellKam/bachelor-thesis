# Capstones — results and tooling metrics

Two programs, each written once per language and checked by one shared host that is identical for all four:
`host/life.mjs` (instantiates the module, runs 100 generations, compares every cell with a JavaScript reference) and
`host/cat.mjs` (runs the module under Wasmtime, checks `stdout == stdin` for text, empty and 100,000 random bytes).
Sources in `capstones/<name>/<lang>/` (build command in `cmd`), logs in `results/capstones/`, run with
`sh capstones/run.sh <life|cat> <lang>` inside the language's container. Same toolchain versions and **release** builds as the probes.

**All eight programs passed their checks.** What differs is how they got there.

## Life (64×64 Game of Life, double-buffered in linear memory, host reads the grid straight from the exported memory)

| | Rust | Zig | AssemblyScript | MoonBit |
|---|---|---|---|---|
| passes shared host unchanged | yes | yes | yes | yes |
| release size (bytes) | 945 | 538 | 408 | 2,236 |
| source lines (non-blank) | 63 | 42 | 38 | 44 |
| config lines (manifest etc.) | 6 | 0 | 0 | 20 |
| files in project dir (excl. `cmd`/`out.wasm`) | 3 (incl. generated `Cargo.lock`) | 1 | 1 | 3 |
| build commands | 1 (`cargo build`) | 1 | 1 | 1 (`moon build`) |
| tools beyond the compiler | none (cargo, `rust-lld` are bundled) | none | npm install of `assemblyscript` + `binaryen` + `long` (lockfile) | none |
| unrequested imports | 0 | 0 | 0 | 0 |
| unrequested exports | 0 | 0 | 0 | 0 |
| how it reaches memory | `static mut` + raw pointers (`unsafe`) | `var` array (safe) | `memory.data()` + `load`/`store` builtins | inline WAT `load8`/`store8` at fixed addresses |

Things each language needed that the others did not:
- **Rust:** `unsafe` for the import call and every raw-pointer access; `#[panic_handler]` for `no_std`; `-> *mut u8` pointer arithmetic.
- **Zig:** `-fno-entry -rdynamic` to build a library-shaped module; plain arrays gave a stable address, so `cells_ptr()` was one line.
- **AssemblyScript:** nothing special; `memory.data(n)` reserves static memory, which is the shortest route to a stable buffer.
- **MoonBit:** two things. MoonBit has no way to take the address of an array, so the grids sit at fixed addresses below the heap
  (`heap-start-address: 16384` in `moon.pkg.json`) and are read and written through hand-written inline WAT (`extern "wasm"`).
  And the name `init` is reserved (it must be the start function), so the exported `init` is `init_grid` renamed via
  `"exports": ["init_grid:init", …]`; the `#export_name` attribute was rejected ("can only be used in a foreign library").

## Cat (read stdin, write stdout, WASI Preview 1)

| | Rust | Zig | AssemblyScript | MoonBit |
|---|---|---|---|---|
| passes shared host | yes | yes | yes | yes |
| release size (bytes) | 76,673 | 360 | 203 | 414 |
| source lines | 6 | 13 | 18 | 24 |
| config lines | 4 | 0 | 0 | 12 |
| how it reaches WASI | std (`io::copy`, target `wasm32-wasip1`) | `std.os.wasi` bindings | hand-declared `@external` imports | hand-declared imports, `main` → `_start` |
| WASI imports in the module | 5 (`environ_get`, `environ_sizes_get`, `fd_read`, `fd_write`, `proc_exit`) | 3 (`proc_exit`, `fd_read`, `fd_write`) | 2 | 2 |
| extra exports | `__main_void` | none | none | none |

- **Rust** is by far the shortest source (6 lines) and by far the largest module (76,673 bytes, 5 WASI imports) because the standard
  library comes with it. Zig's equivalent through its `std.os.wasi` bindings is 360 bytes.
- **AssemblyScript, MoonBit:** neither of them offered a ready-made WASI layer that I used, so I declared `fd_read`/`fd_write`
  myself and laid out the iovec in memory by hand. For AssemblyScript an official `@assemblyscript/wasi-shim` package exists but
  I did **not** try it, so this table does not show the idiomatic route there.
- **MoonBit** `main` is emitted as the `_start` export automatically (as its docs say), so no export configuration was needed.

## Limits of this evidence

- Only the **raw** build was done. The "idiomatic" builds from the study plan (README §7), which would use each ecosystem's recommended
  glue (e.g. `wasm-bindgen`, the AssemblyScript loader/WASI shim), were not written, so tooling counts here are the *minimum* each
  language needs, not what a typical project uses.
- Source-line and config-line counts are of my own programs, written once, and depend on how I wrote them. Treat them as rough.
- Not measured: build time, determinism (build twice, compare hashes), a WASI build of Life (deliberately not done: it needs no OS interface, so all five used the freestanding target; only `cat` used WASI targets), and
  MoonBit's `wasm-gc` backend.

