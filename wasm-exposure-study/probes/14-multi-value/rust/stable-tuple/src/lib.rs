#![no_std]

// Rust ABI, tuple return; the toolchain already enables the multivalue target feature by default.
#[unsafe(no_mangle)]
pub fn divmod(a: u32, b: u32) -> (u32, u32) {
    (a / b, a % b)
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
