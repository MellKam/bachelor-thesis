#![no_std]
#![feature(asm_experimental_arch)]
// The Rust declaration says bump takes an i32; the assembly defines it as () -> i32.
use core::arch::global_asm;

unsafe extern "C" {
    fn bump(x: i32) -> i32;
}

#[unsafe(no_mangle)]
pub extern "C" fn run() -> i32 {
    unsafe { bump(7) }
}

global_asm!(
    ".globl bump",
    ".section .text.bump,\"\",@",
    "bump:",
    ".functype bump () -> (i32)", "i32.const 1", "end_function",
);

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
