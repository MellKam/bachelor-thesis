// The shift idiom is not turned into the sign-extension instructions; they are written as inline Wasm text.
extern "wasm" fn ext8_raw(x : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.extend8_s)

extern "wasm" fn ext16_raw(x : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.extend16_s)

pub fn sat_trunc(x : Double) -> Int { x.to_int() }
pub fn ext8(x : Int) -> Int { ext8_raw(x) }
pub fn ext16(x : Int) -> Int { ext16_raw(x) }
