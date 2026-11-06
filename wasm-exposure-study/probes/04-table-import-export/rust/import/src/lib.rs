#![no_std]

fn double(x: i32) -> i32 {
    x * 2
}

fn plus100(x: i32) -> i32 {
    x + 100
}

// An exported mutable static: the optimiser cannot assume what is in it, so the indirect call stays.
#[unsafe(no_mangle)]
pub static mut SLOTS: [fn(i32) -> i32; 2] = [double, plus100];

#[unsafe(no_mangle)]
pub extern "C" fn call_slot(slot: i32, x: i32) -> i32 {
    unsafe { (*(&raw const SLOTS))[slot as usize & 1](x) }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
