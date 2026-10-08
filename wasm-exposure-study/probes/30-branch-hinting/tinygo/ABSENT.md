# 30 Branch hinting — TinyGo: no probe

Go has no `likely`/`unlikely` construct or compiler directive for branch weights, and TinyGo's LLVM backend does not emit the `metadata.code.branch_hint` section.

Result: **Absent (not found)**.
