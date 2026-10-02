#![no_std]

fn double(x: i32) -> i32 {
    x * 2
}

fn plus100(x: i32) -> i32 {
    x + 100
}

static SLOTS: [fn(i32) -> i32; 2] = [double, plus100];

// black_box keeps the optimiser from inlining the lookup, so the call stays an indirect call.
#[unsafe(no_mangle)]
pub extern "C" fn call_slot(slot: i32, x: i32) -> i32 {
    core::hint::black_box(&SLOTS)[slot as usize & 1](x)
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
