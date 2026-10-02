fn fd_read(fd : Int, iovs : Int, iovs_len : Int, nread : Int) -> Int = "wasi_snapshot_preview1" "fd_read"

fn fd_write(fd : Int, iovs : Int, iovs_len : Int, nwritten : Int) -> Int = "wasi_snapshot_preview1" "fd_write"

extern "wasm" fn load32(addr : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.load)

extern "wasm" fn store32(addr : Int, v : Int) -> Unit =
  #|(func (param i32 i32) local.get 0 local.get 1 i32.store)

// iovec at 1024, result at 1040, buffer at 2048; the heap starts at 16384.
fn main {
  store32(1024, 2048)
  while true {
    store32(1028, 4096)
    if fd_read(0, 1024, 1, 1040) != 0 {
      break
    }
    let n = load32(1040)
    if n == 0 {
      break
    }
    store32(1028, n)
    if fd_write(1, 1024, 1, 1040) != 0 {
      break
    }
  }
}
