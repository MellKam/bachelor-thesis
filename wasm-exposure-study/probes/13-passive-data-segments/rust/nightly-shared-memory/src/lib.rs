#![no_std]

static DATA: [u8; 4] = *b"WASM";

#[unsafe(no_mangle)]
pub extern "C" fn load(dst: i32) {
    unsafe { core::ptr::copy_nonoverlapping(core::hint::black_box(&DATA).as_ptr(), dst as *mut u8, 4) }
}

#[unsafe(no_mangle)]
pub extern "C" fn peek(addr: i32) -> i32 {
    unsafe { core::ptr::read_volatile(addr as *const u8) as i32 }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
