#![no_std]

#[unsafe(no_mangle)]
pub static DATA: [u8; 4] = *b"WASM";

#[unsafe(no_mangle)]
pub extern "C" fn peek(addr: i32) -> i32 {
    unsafe { core::ptr::read_volatile(addr as usize as *const u8) as i32 }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
