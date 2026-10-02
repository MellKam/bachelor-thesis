#![no_std]

use core::arch::wasm32::{i32x4_add, i32x4_splat, v128, v128_store};
use core::hint::black_box;
use core::ptr::{read_volatile, addr_of_mut};

#[unsafe(no_mangle)]
pub extern "C" fn popcount(x: u32) -> u32 {
    x.count_ones()
}

static mut OUT: [i32; 4] = [0; 4];

// SIMD is an intrinsic, gated per function by target_feature. LLVM only keeps `i32x4.add` if every lane
// of the result is used and the inputs are not provably splats: otherwise it rewrites the add to scalar
// code (splat(a) + splat(b) -> splat(a + b); lane-0-only use -> i32.add). Hence black_box on the inputs
// and a whole-vector store of the result.
#[unsafe(no_mangle)]
#[target_feature(enable = "simd128")]
pub extern "C" fn simd_add(a: i32, b: i32) -> i32 {
    let v = i32x4_add(black_box(i32x4_splat(a)), black_box(i32x4_splat(b)));
    unsafe {
        v128_store(addr_of_mut!(OUT) as *mut v128, v);
        read_volatile(addr_of_mut!(OUT) as *const i32)
    }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
