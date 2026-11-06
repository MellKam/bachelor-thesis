#![no_std]

static mut BUF: [u8; 512] = [0; 512];

#[unsafe(no_mangle)]
pub extern "C" fn bulk_test(n: i32) -> i32 {
    unsafe {
        let p = (&raw mut BUF) as *mut u8;
        core::ptr::write_bytes(p, 5, n as usize);
        let p = core::hint::black_box(p); // otherwise LLVM turns memcpy-of-memset into a second memset
        core::ptr::copy_nonoverlapping(p, p.add(256), n as usize);
        let mut s = 0i32;
        for i in 0..n as usize { s += core::ptr::read_volatile(p.add(256 + i)) as i32; }
        s
    }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
