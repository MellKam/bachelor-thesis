#![feature(asm_experimental_arch)]
#![no_std]
#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

core::arch::global_asm!(r#"
.section .text.divmod,"",@
.globl divmod
.export_name divmod, divmod
divmod:
  .functype divmod (i32, i32) -> (i32, i32)
  local.get 0
  local.get 1
  i32.div_u
  local.get 0
  local.get 1
  i32.rem_u
  end_function
"#);
