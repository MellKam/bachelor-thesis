#![no_std]

#[unsafe(no_mangle)]
pub extern "C" fn touch() -> i32 {
    unsafe {
        let p = 16usize as *mut i32;
        p.write_volatile(42);
        p.read_volatile()
    }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
