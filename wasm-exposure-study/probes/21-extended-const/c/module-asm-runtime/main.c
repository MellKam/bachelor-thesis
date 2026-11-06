__asm__(
    ".globaltype base, i32, immutable\n"
    ".import_module base, host\n"
    ".import_name base, base\n"
    ".section .text.get_g,\"\",@\n"
    ".globl get_g\n"
    ".export_name get_g, get_g\n"
    "get_g:\n"
    "  .functype get_g () -> (i32)\n"
    "  global.get base\n"
    "  i32.const 12\n"
    "  i32.add\n"
    "  end_function\n");
