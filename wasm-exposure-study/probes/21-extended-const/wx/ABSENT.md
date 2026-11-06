# 21-extended-const — WX: Absent (confirmed)

A global's initializer is evaluated at compile time into a constant (`global_values`) and one that is not a constant expression is an error (E2015), so a global cannot be initialised from an imported global. The module's globals always get a plain constant initializer.

**Status:** Deferred on purpose. Lazy initialisation of globals was attempted and postponed until the design is settled; extended constants follow from it. Absent in the current compiler, not ruled out by the language design.
