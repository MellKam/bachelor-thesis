#![no_std]

#[unsafe(no_mangle)] pub extern "C" fn sat_trunc(x: f64) -> i32 { x as i32 }
#[unsafe(no_mangle)] pub extern "C" fn ext8(x: i32) -> i32 { x as i8 as i32 }
#[unsafe(no_mangle)] pub extern "C" fn ext16(x: i32) -> i32 { x as i16 as i32 }

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
