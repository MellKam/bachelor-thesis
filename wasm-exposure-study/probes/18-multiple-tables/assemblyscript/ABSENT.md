# 18 multiple tables — assemblyscript: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

Function-typed values share one implicit table (feature 03); `--tableBase` only moves it. No language construct or option declares a second table. Binaryen's `addTable` is reachable only via the `afterCompile` transform hook on the already-compiled module, which bypasses AssemblyScript's own compiler (see `07-custom-sections/assemblyscript/ABSENT.md` for why that doesn't count as the language reaching it).

Result: **Absent (confirmed)**.
