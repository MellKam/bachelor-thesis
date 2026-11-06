# 18 multiple tables — moonbit-gc: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

In the feature 03 probe the module has no funcref table, and nothing in the language declares one. Same structural reason as feature 04: moonc's own module-construction code builds a single `table` field, not a list.

Result: **Absent (confirmed)**.
