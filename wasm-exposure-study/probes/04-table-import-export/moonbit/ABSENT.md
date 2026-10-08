# 04 Table import and export — MoonBit (wasm backend): no probe

`moonc link-core -help` lists memory options (`-export-memory-name`, `-import-memory-module`, `-import-memory-name`, `-memory-limits-min/max`, `-shared-memory`) and no table option, and `moon.pkg.json` `link.wasm` has no table key. The only table is the implicit one holding function values (feature 03).

Result: **Absent (not found)**.
