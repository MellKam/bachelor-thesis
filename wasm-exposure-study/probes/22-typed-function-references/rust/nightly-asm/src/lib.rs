#![feature(asm_experimental_arch)]
#![no_std]

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

core::arch::global_asm!(r#"
.section .text.double,"",@
.globl double
.export_name double, double
double:
  .functype double (i32) -> (i32)
  local.get 0
  i32.const 2
  i32.mul
  end_function

.section .text.apply,"",@
.globl apply
.export_name apply, apply
apply:
  .functype apply (i32) -> (i32)
  local.get 0
  ref.func double
  call_ref (i32) -> (i32)
  end_function
"#);
