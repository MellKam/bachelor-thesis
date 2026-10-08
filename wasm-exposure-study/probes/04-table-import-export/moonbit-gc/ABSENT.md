# 04 Table import and export — MoonBit (wasm-gc backend): no probe

`moonc link-core -help` lists memory options (`-export-memory-name`, `-import-memory-module`, `-import-memory-name`, `-memory-limits-min/max`, `-shared-memory`) and no table option, and `moon.pkg.json` `link.wasm-gc` has no table key. The wasm-gc module has no table at all (feature 03).

Result: **Absent (not found)**.
