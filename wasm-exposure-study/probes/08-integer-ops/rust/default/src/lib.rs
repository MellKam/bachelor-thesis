#![no_std]

#[unsafe(no_mangle)] pub extern "C" fn i_add(a: i32, b: i32) -> i32 { a.wrapping_add(b) }
#[unsafe(no_mangle)] pub extern "C" fn i_sub(a: i32, b: i32) -> i32 { a.wrapping_sub(b) }
#[unsafe(no_mangle)] pub extern "C" fn i_mul(a: i32, b: i32) -> i32 { a.wrapping_mul(b) }
#[unsafe(no_mangle)] pub extern "C" fn i_div(a: i32, b: i32) -> i32 { a / b }
#[unsafe(no_mangle)] pub extern "C" fn i_rem(a: i32, b: i32) -> i32 { a % b }
#[unsafe(no_mangle)] pub extern "C" fn i_clz(a: i32) -> i32 { a.leading_zeros() as i32 }
#[unsafe(no_mangle)] pub extern "C" fn i_ctz(a: i32) -> i32 { a.trailing_zeros() as i32 }
#[unsafe(no_mangle)] pub extern "C" fn i_popcnt(a: i32) -> i32 { a.count_ones() as i32 }
#[unsafe(no_mangle)] pub extern "C" fn i_rotl(a: i32, n: i32) -> i32 { (a as u32).rotate_left(n as u32) as i32 }
#[unsafe(no_mangle)] pub extern "C" fn i_rotr(a: i32, n: i32) -> i32 { (a as u32).rotate_right(n as u32) as i32 }

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
