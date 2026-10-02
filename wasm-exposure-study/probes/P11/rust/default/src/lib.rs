#![no_std]

#[used]
#[unsafe(link_section = "meta")]
static META: [u8; 1] = *b"x";

#[unsafe(no_mangle)]
pub extern "C" fn nop() {}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
