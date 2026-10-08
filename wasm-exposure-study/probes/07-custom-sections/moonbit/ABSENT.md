# 07 custom sections — moonbit: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

No attribute, package option or builtin for emitting a custom section was found in `moon.pkg.json` link options, the language documentation or the core library (`grep -ri "custom section"` over `/opt/moon/lib/core` finds nothing). Inline Wasm text (`extern "wasm"`) accepts a function body only, not a section.

Result: **Absent (not found)**.
