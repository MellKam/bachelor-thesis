/* The C declaration says bump takes one int; the assembly defines it as () -> i32. Does the C compiler relate the two? */
extern int bump(int);
__attribute__((export_name("run"))) int run(void) { return bump(7); }
__asm__(
    ".globl bump\n"
    ".section .text.bump,\"\",@\n"
    "bump:\n"
    "  .functype bump () -> (i32)\n"
    "  i32.const 1\n"
    "  end_function\n");
