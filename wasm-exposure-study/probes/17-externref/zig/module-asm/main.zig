// Zig has no externref type; module-level assembly can still type a function with it (needs +reference_types).
comptime {
    asm (
        \\.section .text.identity,"",@
        \\.globl identity
        \\.export_name identity, identity
        \\identity:
        \\  .functype identity (externref) -> (externref)
        \\  local.get 0
        \\  end_function
    );
}
