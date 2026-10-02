#![no_std]

static mut G: i32 = 0;

extern "C" fn init() {
    unsafe { G = 7 }
}

// A constructor, not a start section: wasm-ld collects .init_array entries into __wasm_call_ctors.
#[used]
#[unsafe(link_section = ".init_array.100")]
static INIT: extern "C" fn() = init;

#[unsafe(no_mangle)]
pub extern "C" fn get() -> i32 {
    unsafe { core::ptr::read_volatile(&raw const G) }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
