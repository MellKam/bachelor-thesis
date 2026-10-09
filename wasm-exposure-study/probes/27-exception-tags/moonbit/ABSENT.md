# 27 exception tags — moonbit: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

See the `raise` variant: errors compile to ordinary control flow; the module has no tag section.

Result: **Absent (confirmed)**.

Checked on 2026-10-09: `moonc -test-mode` (set only by `moon test`, and not reachable from `moon.pkg.json`) builds a wasm-gc module that imports a host `exception.tag` and a `throw` function; it contains no `try_table`, no tag definition and no `throw` instruction. It is a host callback for panics in tests, not WebAssembly exception handling.
