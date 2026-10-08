#![no_std]

// Memory is not declared in source. Its limits, stack size and export name are linker options (see build.sh).
#[unsafe(no_mangle)]
pub extern "C" fn touch() -> i32 {
    0
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
