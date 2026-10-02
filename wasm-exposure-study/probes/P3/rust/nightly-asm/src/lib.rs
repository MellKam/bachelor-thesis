#![feature(asm_experimental_arch)]
#![no_std]
#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

// A function body in assembly that copies between memory 1 and memory 0. The assembler accepts it; see the attempt log.
core::arch::global_asm!(r#"
.section .text.copy_test,"",@
.globl copy_test
.export_name copy_test, copy_test
copy_test:
  .functype copy_test () -> (i32)
  i32.const 0
  i32.const 0
  i32.const 4
  memory.copy 1, 0
  i32.const 0
  i32.load8_u 0
  end_function
"#);
