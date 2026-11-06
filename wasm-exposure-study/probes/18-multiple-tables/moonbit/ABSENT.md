# 18 multiple tables — moonbit: no probe

No program was written, because no language construct, attribute or option was found to attempt it with.

The only table in a MoonBit module is the implicit one holding the closures/function values (see feature 03). No syntax or link option declares a table. Same structural reason as feature 04: moonc's own module-construction code builds a single `table` field, not a list.

Result: **Absent (confirmed)**.
