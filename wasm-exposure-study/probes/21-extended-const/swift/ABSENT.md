# 21 Extended constant expressions — Swift: no probe

A Swift global is linear-memory data, never a Wasm global (feature 10: `extern-var`, `expose-var`; `@_extern` on a variable declares a data symbol,
`@_expose(wasm)` accepts global functions only). Without a Wasm global to import or define there is nothing for a global initialiser
to combine with arithmetic. A top-level `let g = base + 12` is a run-time initialiser (lazy, behind a once-guard that Embedded Swift does
not provide), not a constant expression in the global section.

Result: **Absent (confirmed)**.
