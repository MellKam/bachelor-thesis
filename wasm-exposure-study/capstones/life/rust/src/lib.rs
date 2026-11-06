#![no_std]

const W: usize = 64;
const H: usize = 64;
const N: usize = W * H;

static mut BUF: [u8; 2 * N] = [0; 2 * N];
static mut CUR: usize = 0;

#[link(wasm_import_module = "host")]
unsafe extern "C" {
    fn random() -> i32;
}

unsafe fn base() -> *mut u8 {
    &raw mut BUF as *mut u8
}

#[unsafe(no_mangle)]
pub extern "C" fn init() {
    unsafe {
        let b = base();
        for i in 0..N {
            *b.add(i) = (random() & 1) as u8;
        }
        CUR = 0;
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn step() {
    unsafe {
        let b = base();
        let cur = b.add(CUR * N);
        let nxt = b.add((1 - CUR) * N);
        for y in 0..H {
            for x in 0..W {
                let mut n = 0u8;
                for dy in [H - 1, 0, 1] {
                    for dx in [W - 1, 0, 1] {
                        if dy == 0 && dx == 0 {
                            continue;
                        }
                        n += *cur.add(((y + dy) % H) * W + (x + dx) % W);
                    }
                }
                let alive = *cur.add(y * W + x) != 0;
                *nxt.add(y * W + x) = (n == 3 || (alive && n == 2)) as u8;
            }
        }
        CUR = 1 - CUR;
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cells_ptr() -> i32 {
    unsafe { base().add(CUR * N) as i32 }
}

#[unsafe(no_mangle)]
pub extern "C" fn width() -> i32 {
    W as i32
}

#[unsafe(no_mangle)]
pub extern "C" fn height() -> i32 {
    H as i32
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}
