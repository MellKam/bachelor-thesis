# 07 custom sections — assemblyscript: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

No decorator or builtin emits a custom section. `asc --help` has `--tableBase` and `--memoryBase` (placement of emitted segments) but nothing for custom sections. `asc`'s `afterCompile` transform hook can hand a post-compile JS plugin a raw Binaryen `Module` with `addCustomSection` (proven in production by the `as-bind` library), but that bypasses AssemblyScript's own compiler/type system to call a different tool's IR builder API on the already-emitted module — not the language producing the feature. Accepting it would need to apply symmetrically to any toolchain whose output can be post-processed with Binaryen/wasm-opt, which would break the comparison.

Result: **Absent (confirmed)**.
