// MoonBit has no rotate operation. i32.rotl can be written as inline Wasm text; the inline parser has no i32.rotr, so rotr stays a shift idiom.
extern "wasm" fn rotl_raw(a : Int, n : Int) -> Int =
  #|(func (param i32 i32) (result i32) local.get 0 local.get 1 i32.rotl)

pub fn i_add(a : Int, b : Int) -> Int { a + b }
pub fn i_sub(a : Int, b : Int) -> Int { a - b }
pub fn i_mul(a : Int, b : Int) -> Int { a * b }
pub fn i_div(a : Int, b : Int) -> Int { a / b }
pub fn i_rem(a : Int, b : Int) -> Int { a % b }
pub fn i_clz(a : Int) -> Int { a.clz() }
pub fn i_ctz(a : Int) -> Int { a.ctz() }
pub fn i_popcnt(a : Int) -> Int { a.popcnt() }
pub fn i_rotl(a : Int, n : Int) -> Int { rotl_raw(a, n) }
pub fn i_rotr(a : Int, n : Int) -> Int { (a.reinterpret_as_uint() >> n).reinterpret_as_int() | (a << (32 - n)) }
