#![no_std]

#[link(wasm_import_module = "host")]
unsafe extern "C" {
    fn log(x: i32);
}

#[unsafe(no_mangle)]
pub extern "C" fn run() {
    unsafe { log(42) }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
