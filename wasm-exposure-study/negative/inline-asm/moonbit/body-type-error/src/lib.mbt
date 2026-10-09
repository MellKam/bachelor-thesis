// MoonBit signature (Int) -> Int, the Wasm body applies a float instruction to an i32.
extern "wasm" fn raw(x : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 f32.neg)

pub fn run() -> Int {
  raw(5)
}
