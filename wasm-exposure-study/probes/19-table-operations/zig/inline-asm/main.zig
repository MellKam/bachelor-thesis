// There is no Zig builtin for table operations; the only route is the LLVM assembler through inline assembly.
export fn table_ops(n: i32) i32 {
    return asm volatile (
        \\ref.null_func
        \\local.get %[n]
        \\table.grow 0
        \\drop
        \\table.size 0
        : [ret] "=r" (-> i32),
        : [n] "r" (n),
    );
}
