#![feature(asm_experimental_arch)]
#![no_std]
#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

// Module-level assembly: try_table with catch_all_ref captures the exception, throw_ref rethrows it,
// and an outer try_table with a tagged catch receives it. Needs `global_asm!` on wasm32 (nightly).
core::arch::global_asm!(r#"
.tagtype payload_tag i32
payload_tag:

.section .text.rethrow_test,"",@
.globl rethrow_test
.export_name rethrow_test, rethrow_test
rethrow_test:
  .functype rethrow_test (i32) -> (i32)
  block i32
    try_table (catch payload_tag 0)
      block exnref
        try_table (catch_all_ref 0)
          local.get 0
          throw payload_tag
        end_try_table
        unreachable
      end_block
      throw_ref
    end_try_table
    unreachable
  end_block
  end_function
"#);
