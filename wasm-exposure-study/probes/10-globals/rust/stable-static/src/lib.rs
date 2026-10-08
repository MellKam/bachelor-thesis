#![no_std]

// The closest stable thing to a Wasm global: a static. It lives in linear memory, not in the global section.
#[unsafe(no_mangle)]
pub static mut COUNTER: i32 = 0;

#[unsafe(no_mangle)]
pub extern "C" fn bump() -> i32 {
    unsafe {
        COUNTER += 1;
        COUNTER
    }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
