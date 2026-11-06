#![no_std]

#[cold]
#[inline(never)]
fn rare() -> i32 {
    core::hint::black_box(-1)
}

#[unsafe(no_mangle)]
pub extern "C" fn classify(x: i32) -> i32 {
    if x < 0 { rare() } else { x * 2 }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
