#![no_std]
use core::arch::wasm32::*;

#[unsafe(no_mangle)]
pub extern "C" fn simd_add(a: i32, b: i32) -> i32 {
    i32x4_extract_lane::<0>(i32x4_add(i32x4_splat(a), i32x4_splat(b)))
}

#[unsafe(no_mangle)]
pub extern "C" fn simd_shuffle(a: i32, b: i32) -> i32 {
    i32x4_extract_lane::<0>(i8x16_shuffle::<16, 17, 18, 19, 4, 5, 6, 7, 24, 25, 26, 27, 12, 13, 14, 15>(i32x4_splat(a), i32x4_splat(b)))
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
