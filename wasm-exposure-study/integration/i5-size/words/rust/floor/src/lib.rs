#![no_std]
// `words`, floor ABI (INTEGRATION.md): export memory, alloc(len) -> ptr, analyse(ptr, len) -> ptr to { words, bytes, longest_ptr, longest_len }.

static mut HEAP: [u8; 1 << 20] = [0; 1 << 20];
static mut TOP: usize = 0;
static mut RECORD: [u32; 4] = [0; 4];

#[unsafe(no_mangle)]
pub extern "C" fn alloc(len: usize) -> *mut u8 {
    unsafe {
        let p = (&raw mut HEAP as *mut u8).add(TOP);
        TOP += (len + 7) & !7;
        p
    }
}

fn is_ws(c: u8) -> bool {
    c == b' ' || c == b'\t' || c == b'\n' || c == b'\r'
}

#[unsafe(no_mangle)]
pub extern "C" fn analyse(ptr: *const u8, len: usize) -> *const u32 {
    unsafe {
        let s = core::slice::from_raw_parts(ptr, len);
        let (mut words, mut best, mut best_at, mut i) = (0u32, 0usize, 0usize, 0usize);
        while i < len {
            while i < len && is_ws(s[i]) { i += 1; }
            let start = i;
            while i < len && !is_ws(s[i]) { i += 1; }
            if i > start {
                words += 1;
                if i - start > best { best = i - start; best_at = start; }
            }
        }
        TOP = 0;
        RECORD = [words, len as u32, ptr.add(best_at) as u32, best as u32];
        &raw const RECORD as *const u32
    }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
