# 20-tail-calls — WX: Absent (confirmed)

No `return_call` form. The backend never emits `return_call` and does not turn mutual tail recursion into a loop, so the probe would only show stack exhaustion; none was written.

**Status:** Not implemented yet; fits the design, needs research. Absent in the current compiler, not ruled out by the language design.
