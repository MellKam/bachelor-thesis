#![no_std]
use core::arch::wasm32::*;

// Vectors come from and go to linear memory, so the optimiser cannot fold them into scalar code.
#[unsafe(no_mangle)]
#[target_feature(enable = "simd128")]
pub extern "C" fn v_copy(p: i32) -> i32 {
    unsafe {
        let p = p as *mut u8;
        v128_store(p.add(16) as *mut v128, v128_load(p as *const v128));
        p.add(16).read_volatile() as i32
    }
}

#[unsafe(no_mangle)]
#[target_feature(enable = "simd128")]
pub extern "C" fn v_select(p: i32) -> i32 {
    unsafe {
        let p = p as *mut u8;
        let (a, b, m) = (v128_load(p as *const v128), v128_load(p.add(16) as *const v128), v128_load(p.add(32) as *const v128));
        let r = v128_bitselect(a, b, m);
        v128_store(p.add(48) as *mut v128, r);
        i32x4_extract_lane::<0>(r)
    }
}

#[unsafe(no_mangle)]
#[target_feature(enable = "simd128")]
pub extern "C" fn v_narrow(p: i32) -> i32 {
    unsafe {
        let p = p as *mut u8;
        let r = i8x16_narrow_i16x8(v128_load(p as *const v128), v128_load(p.add(16) as *const v128));
        v128_store(p.add(32) as *mut v128, r);
        p.add(39).read_volatile() as i32
    }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
