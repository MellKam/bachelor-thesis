#![no_std]

// The same assembly as the nightly variant, without the feature gate: expected to be rejected (E0658).
core::arch::global_asm!(r#"
.section .text.identity,"",@
.globl identity
.export_name identity, identity
identity:
  .functype identity (externref) -> (externref)
  local.get 0
  end_function
"#);

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
