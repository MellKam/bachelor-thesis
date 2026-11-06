/* The assembly body is ill-typed on its own (i32.add with one operand). */
extern int bump(void);
__attribute__((export_name("run"))) int run(void) { return bump(); }
__asm__(
    ".globl bump\n"
    ".section .text.bump,\"\",@\n"
    "bump:\n"
    "  .functype bump () -> (i32)\n"
    "  i32.const 1\n"
    "  i32.add\n"
    "  end_function\n");
