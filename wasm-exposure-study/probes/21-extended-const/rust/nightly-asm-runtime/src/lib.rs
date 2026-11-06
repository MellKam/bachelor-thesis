#![feature(asm_experimental_arch)]
#![no_std]

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

core::arch::global_asm!(r#"
.globaltype base, i32, immutable
.import_module base, host
.import_name base, base

.section .text.get_g,"",@
.globl get_g
.export_name get_g, get_g
get_g:
  .functype get_g () -> (i32)
  global.get base
  i32.const 12
  i32.add
  end_function
"#);
