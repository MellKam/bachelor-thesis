// The assembly body is ill-typed on its own (i32.add with one operand).
extern fn bump() i32;
export fn run() i32 {
    return bump();
}
comptime {
    asm (
        \\.globl bump
        \\.section .text.bump,"",@
        \\bump:
        \\  .functype bump () -> (i32)
        \\  i32.const 1
        \\  i32.add
        \\  end_function
    );
}
