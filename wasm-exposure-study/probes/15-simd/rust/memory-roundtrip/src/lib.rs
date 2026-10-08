#![no_std]
use core::arch::wasm32::*;

static mut SA: v128 = i32x4(0, 0, 0, 0);
static mut SB: v128 = i32x4(0, 0, 0, 0);
static mut SC: v128 = i32x4(0, 0, 0, 0);

// The splatted operands go through memory, so the optimiser cannot turn extract(add(splat, splat)) back into a scalar add,
// and the result is used twice (stored, and one lane returned), so the lane extraction is not folded into the loads.
#[unsafe(no_mangle)]
#[target_feature(enable = "simd128")]
pub extern "C" fn simd_add(a: i32, b: i32) -> i32 {
    unsafe {
        let (pa, pb, pc) = (&raw mut SA, &raw mut SB, &raw mut SC);
        pa.write_volatile(i32x4_splat(a));
        pb.write_volatile(i32x4_splat(b));
        let r = i32x4_add(pa.read_volatile(), pb.read_volatile());
        pc.write_volatile(r);
        i32x4_extract_lane::<0>(r)
    }
}

#[unsafe(no_mangle)]
#[target_feature(enable = "simd128")]
pub extern "C" fn simd_shuffle(a: i32, b: i32) -> i32 {
    unsafe {
        let (pa, pb, pc) = (&raw mut SA, &raw mut SB, &raw mut SC);
        pa.write_volatile(i32x4_splat(a));
        pb.write_volatile(i32x4_splat(b));
        let r = i8x16_shuffle::<16, 17, 18, 19, 4, 5, 6, 7, 24, 25, 26, 27, 12, 13, 14, 15>(pa.read_volatile(), pb.read_volatile());
        pc.write_volatile(r);
        i32x4_extract_lane::<0>(r)
    }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
