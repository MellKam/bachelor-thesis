// memory.init names its segment by index; with a single data segment it is segment 0.
__asm__(
    ".globl load\n"
    ".export_name load, load\n"
    "load:\n"
    "  .functype load (i32) -> ()\n"
    "  local.get 0\n"
    "  i32.const 0\n"
    "  i32.const 4\n"
    "  memory.init 0, 0\n"
    "  data.drop 0\n"
    "  end_function\n"
    ".section .data.msg,\"\",@\n"
    ".globl msg\n"
    "msg:\n"
    "  .ascii \"WASM\"\n"
    "  .size msg, 4\n");

__attribute__((export_name("peek"))) int peek(int addr) { return *(volatile unsigned char *)addr; }
