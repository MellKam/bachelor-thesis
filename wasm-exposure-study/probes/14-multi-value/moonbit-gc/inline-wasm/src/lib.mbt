// MoonBit has no type for a two-result function, so its signature here is a stand-in: the Wasm text declares the real one.
// Exported directly, the module exports `divmod : (i32, i32) -> (i32, i32)`. moonc does not check the text against the signature.
pub extern "wasm" fn divmod(a : Int, b : Int) -> Int =
  #|(func (param i32) (param i32) (result i32) (result i32) local.get 0 local.get 1 i32.div_u local.get 0 local.get 1 i32.rem_u)
