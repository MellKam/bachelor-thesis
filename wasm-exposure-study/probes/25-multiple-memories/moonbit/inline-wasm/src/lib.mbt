extern "wasm" fn copy_raw() -> Int =
  #|(func (result i32) i32.const 0 i32.const 0 i32.const 4 memory.copy 1 0 i32.const 0 i32.load8_u)

pub fn copy_test() -> Int { copy_raw() }
