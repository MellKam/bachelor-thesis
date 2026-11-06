# 24 GC casts, subtyping, i31, packed fields — Swift: no probe

Follows from feature 23: `ref.test`/`ref.cast`, declared subtypes, `i31` and packed arrays all operate on GC struct and array types,
which Swift cannot declare. Swift's class hierarchies and `as?` casts are implemented by the Swift runtime over linear-memory metadata
(and are unavailable in Embedded Swift for non-class existentials); none of it becomes a Wasm cast.

Result: **Absent (confirmed)**.
