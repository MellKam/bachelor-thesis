#![no_std]
#![feature(asm_experimental_arch)]
// The assembly body is ill-typed on its own (i32.add with one operand).
use core::arch::global_asm;

unsafe extern "C" {
    fn bump() -> i32;
}

#[unsafe(no_mangle)]
pub extern "C" fn run() -> i32 {
    unsafe { bump() }
}

global_asm!(
    ".globl bump",
    ".section .text.bump,\"\",@",
    "bump:",
    ".functype bump () -> (i32)", "i32.const 1", "i32.add", "end_function",
);

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
