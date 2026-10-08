#![no_std]
use core::arch::wasm32::*;

#[unsafe(no_mangle)]
#[target_feature(enable = "simd128", enable = "relaxed-simd")]
pub extern "C" fn relaxed_madd(a: f32, b: f32, c: f32) -> f32 {
    f32x4_extract_lane::<0>(f32x4_relaxed_madd(f32x4_splat(a), f32x4_splat(b), f32x4_splat(c)))
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
