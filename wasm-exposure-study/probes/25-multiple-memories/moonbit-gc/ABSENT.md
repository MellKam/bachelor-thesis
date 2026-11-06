# 25 multiple memories — moonbit-gc: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

The GC backend output has at most one small memory; no option declares more. Confirmed: moonc's own module-construction code builds a single `mem` field, not a list, and moon.pkg.json's memory options are all singular.

Result: **Absent (confirmed)**.
