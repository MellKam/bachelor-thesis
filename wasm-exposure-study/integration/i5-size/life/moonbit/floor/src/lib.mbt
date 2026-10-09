fn random() -> Int = "host" "random"

extern "wasm" fn load8(addr : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.load8_u)

extern "wasm" fn store8(addr : Int, v : Int) -> Unit =
  #|(func (param i32 i32) local.get 0 local.get 1 i32.store8)

// Grids live at fixed addresses below the heap (heap-start-address = 16384).
let base : Int = 1024

let n : Int = 4096

let cur : Ref[Int] = { val: 0 }

// `init` is reserved in MoonBit (it becomes the start function); the export is renamed to `init` in moon.pkg.json.
pub fn init_grid() -> Unit {
  for i = 0; i < n; i = i + 1 {
    store8(base + i, random() & 1)
  }
  cur.val = 0
}

pub fn step() -> Unit {
  let c = base + cur.val * n
  let nx = base + (1 - cur.val) * n
  for y = 0; y < 64; y = y + 1 {
    for x = 0; x < 64; x = x + 1 {
      let mut cnt = 0
      for dy = 0; dy < 3; dy = dy + 1 {
        for dx = 0; dx < 3; dx = dx + 1 {
          if !(dy == 1 && dx == 1) {
            cnt = cnt + load8(c + ((y + 63 + dy) % 64) * 64 + (x + 63 + dx) % 64)
          }
        }
      }
      let alive = load8(c + y * 64 + x) != 0
      store8(nx + y * 64 + x, if cnt == 3 || (alive && cnt == 2) { 1 } else { 0 })
    }
  }
  cur.val = 1 - cur.val
}

pub fn cells_ptr() -> Int {
  base + cur.val * n
}

pub fn width() -> Int {
  64
}

pub fn height() -> Int {
  64
}
