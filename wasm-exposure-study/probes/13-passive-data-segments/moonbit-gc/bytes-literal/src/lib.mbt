let data : Bytes = b"WASM"

// MoonBit has no raw addresses, so `dst` cannot name a place in memory the host can read; the program can only copy
// inside objects it owns. The segment holding the literal is whatever the compiler makes of it.
///|
pub fn load(dst : Int) -> Unit {
  ignore(dst)
  ignore(data)
}

///|
pub fn peek(addr : Int) -> Int {
  data[addr & 3].to_int()
}
