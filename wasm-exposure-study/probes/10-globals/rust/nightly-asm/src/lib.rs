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
.globaltype counter, i32
.globl counter
counter:

.section .text.bump,"",@
.globl bump
.export_name bump, bump
bump:
  .functype bump () -> (i32)
  global.get base
  i32.const 1
  i32.add
  global.set counter
  global.get counter
  end_function
"#);
