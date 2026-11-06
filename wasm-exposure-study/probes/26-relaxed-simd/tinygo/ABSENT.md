# 26 relaxed simd — tinygo: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

No SIMD at all (feature 15, though note feature 15's cell records a possible `-llvm-features +simd128` lead worth re-probing). Even if plain SIMD were reached that way, relaxed-SIMD instructions are only selectable via clang builtins (`__builtin_wasm_relaxed_*`) never exposed through Go syntax, and LLVM's autovectorizer deliberately never auto-selects them since their results are platform-dependent.

Result: **Absent (confirmed)**.
