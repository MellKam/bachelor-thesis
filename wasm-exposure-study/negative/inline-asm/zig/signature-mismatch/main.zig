// The Zig declaration says bump takes an i32; the assembly defines it as () -> i32.
extern fn bump(x: i32) i32;
export fn run() i32 {
    return bump(7);
}
comptime {
    asm (
        \\.globl bump
        \\.section .text.bump,"",@
        \\bump:
        \\  .functype bump () -> (i32)
        \\  i32.const 1
        \\  end_function
    );
}
