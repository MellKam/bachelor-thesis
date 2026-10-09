// MoonBit signature (Int) -> Int, Wasm text takes two parameters.
extern "wasm" fn raw(x : Int) -> Int =
  #|(func (param i32 i32) (result i32) local.get 0 local.get 1 i32.add)

pub fn run() -> Int {
  raw(5)
}
