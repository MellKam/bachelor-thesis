# 21 Extended constant expressions — Zig: no probe

The Wasm global is not a language construct in Zig: `export var counter` exports an immutable global holding the *address* of a
linear-memory variable, and `extern "host" const base` is a data symbol, not a global import (see feature 10, `import-symbols`).
Without a Wasm global to import, a global initialiser cannot combine one with arithmetic, and no Zig syntax or option places an
initialiser expression on a global. Zig does define an `extended_const` target feature, but it is consumed internally by LLVM/the
linker for relocations (PIC data-segment offsets), not exposed as initializer syntax; Zig global initializers are always evaluated by
the comptime interpreter at compile time, which structurally cannot observe a value that only exists at instantiation time — independent
of whether global import (feature 10) is ever fixed.

Result: **Absent (confirmed)**.
