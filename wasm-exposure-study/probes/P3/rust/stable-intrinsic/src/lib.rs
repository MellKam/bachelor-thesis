#![no_std]

// The only stable multi-memory surface in core::arch::wasm32 is the memory index parameter on these intrinsics.
#[unsafe(no_mangle)]
pub extern "C" fn copy_test() -> i32 {
    core::arch::wasm32::memory_size::<1>() as i32
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
