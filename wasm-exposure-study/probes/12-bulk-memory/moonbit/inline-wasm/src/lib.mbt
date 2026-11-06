// Fixed addresses below the heap: MoonBit cannot hand out the address of an array.
extern "wasm" fn fill(addr : Int, v : Int, n : Int) =
  #|(func (param i32 i32 i32) local.get 0 local.get 1 local.get 2 memory.fill)

extern "wasm" fn copy(dst : Int, src : Int, n : Int) =
  #|(func (param i32 i32 i32) local.get 0 local.get 1 local.get 2 memory.copy)

extern "wasm" fn load8(addr : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.load8_u)

pub fn bulk_test(n : Int) -> Int {
  fill(4096, 5, n)
  copy(4352, 4096, n)
  let mut s = 0
  for i in 0..<n {
    s += load8(4352 + i)
  }
  s
}
