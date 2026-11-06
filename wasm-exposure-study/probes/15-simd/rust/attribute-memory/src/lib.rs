#![no_std]
use core::arch::wasm32::*;

static mut A: [i32; 4] = [0; 4];
static mut B: [i32; 4] = [0; 4];
static mut C: [i32; 4] = [0; 4];

// Vectors come from and go to memory, so LLVM cannot scalarise the lane operation away.
#[target_feature(enable = "simd128")]
fn run(a: i32, b: i32, shuffle: bool) -> i32 {
    unsafe {
        let (pa, pb, pc) = ((&raw mut A) as *mut i32, (&raw mut B) as *mut i32, (&raw mut C) as *mut i32);
        for i in 0..4 { pa.add(i).write_volatile(a); pb.add(i).write_volatile(b); }
        let (va, vb) = (v128_load(pa as *const v128), v128_load(pb as *const v128));
        let r = if shuffle { i8x16_shuffle::<16, 17, 18, 19, 4, 5, 6, 7, 24, 25, 26, 27, 12, 13, 14, 15>(va, vb) } else { i32x4_add(va, vb) };
        v128_store(pc as *mut v128, r);
        pc.read_volatile()
    }
}

#[unsafe(no_mangle)]
#[target_feature(enable = "simd128")]
pub extern "C" fn simd_add(a: i32, b: i32) -> i32 { run(a, b, false) }

#[unsafe(no_mangle)]
#[target_feature(enable = "simd128")]
pub extern "C" fn simd_shuffle(a: i32, b: i32) -> i32 { run(a, b, true) }

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
