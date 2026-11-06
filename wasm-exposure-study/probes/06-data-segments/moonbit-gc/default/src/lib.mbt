// Static data goes wherever the compiler puts it; reading it back is how we find out.
let data : Bytes = b"WASM"

pub fn first() -> Int {
  data[0].to_int()
}

extern "wasm" fn load8(addr : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.load8_u)

pub fn peek(addr : Int) -> Int {
  load8(addr)
}
