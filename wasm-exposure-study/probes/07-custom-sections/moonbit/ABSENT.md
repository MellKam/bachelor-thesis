# 07 custom sections — moonbit: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

No attribute, package option or builtin for emitting a custom section was found in `moon.pkg.json` link options, the language documentation or the core library (`grep -ri "custom section"` over `/opt/moon/lib/core` finds nothing). Inline Wasm text (`extern "wasm"`) accepts a function body only, not a section. moonc's compiler source does have a generic custom-section encoder (`dwarfsm_encode_wasm.ml`), but it is wired only to its own DWARF debug-info emission (the `-g` flag), never to developer-supplied name/content.

Result: **Absent (confirmed)**.
