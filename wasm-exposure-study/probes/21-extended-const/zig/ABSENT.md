# 21 Extended constant expressions — Zig: no probe

The Wasm global is not a language construct in Zig: `export var counter` exports an immutable global holding the *address* of a
linear-memory variable, and `extern "host" const base` is a data symbol, not a global import (see feature 10, `import-symbols`).
Without a Wasm global to import, a global initialiser cannot combine one with arithmetic, and no Zig syntax or option places an
initialiser expression on a global.

Result: **Absent (not found)**.
