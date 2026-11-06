#![feature(asm_experimental_arch)]
#![no_std]
#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

core::arch::global_asm!(r#"
.tagtype payload_tag i32
payload_tag:

.section .text.roundtrip,"",@
.globl roundtrip
.export_name roundtrip, roundtrip
roundtrip:
  .functype roundtrip (i32) -> (i32)
  try i32
    local.get 0
    throw payload_tag
  catch payload_tag
  end_try
  end_function
"#);
