// MoonBit signature (Int) -> Int, the Wasm text returns an i64.
extern "wasm" fn raw(x : Int) -> Int =
  #|(func (param i32) (result i64) local.get 0 i64.extend_i32_s)

pub fn run() -> Int {
  raw(5)
}
