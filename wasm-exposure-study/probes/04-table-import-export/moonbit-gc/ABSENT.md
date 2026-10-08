# 04 Table import and export — MoonBit (wasm-gc backend): no probe

`moonc link-core -help` lists memory options (`-export-memory-name`, `-import-memory-module`, `-import-memory-name`, `-memory-limits-min/max`, `-shared-memory`) and no table option, and `moon.pkg.json` `link.wasm-gc` has no table key. The wasm-gc module has no table at all (feature 03). `FuncRef[T]` crosses the FFI boundary as externref, not a table slot, and moonc's module-construction code builds a single `table` field, not a list, reinforcing there is no path to one.

Result: **Absent (confirmed)**.
