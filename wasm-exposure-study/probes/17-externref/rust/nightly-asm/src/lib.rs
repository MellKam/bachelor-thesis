#![feature(asm_experimental_arch)]
#![no_std]
#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

core::arch::global_asm!(r#"
.section .text.identity,"",@
.globl identity
.export_name identity, identity
identity:
  .functype identity (externref) -> (externref)
  local.get 0
  end_function
"#);
