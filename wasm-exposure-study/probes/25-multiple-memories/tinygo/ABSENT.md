# 25 multiple memories — tinygo: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

Go has no notion of more than one address space; the `wasm-unknown` target links exactly one memory, and TinyGo's allocator/runtime is single-memory-aware throughout — a gap shared by most LLVM-based toolchains, not specific to TinyGo.

Result: **Absent (confirmed)**.
