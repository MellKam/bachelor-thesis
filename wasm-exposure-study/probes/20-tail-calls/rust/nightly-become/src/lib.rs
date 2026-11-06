#![feature(explicit_tail_calls)]
#![allow(incomplete_features)]
#![no_std]

#[inline(never)]
fn a(n: i32, acc: i32) -> i32 { if n == 0 { acc } else { become b(n - 1, acc + 1) } }
#[inline(never)]
fn b(n: i32, acc: i32) -> i32 { if n == 0 { acc } else { become a(n - 1, acc + 1) } }

#[unsafe(no_mangle)]
pub extern "C" fn count(n: i32, acc: i32) -> i32 { a(n, acc) }

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
