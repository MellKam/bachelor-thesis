// A MoonBit program cannot name an address; inline Wasm text can, so the vectors are read from and written to the memory the host filled.
extern "wasm" fn v_copy_raw(p : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 local.get 0 v128.load v128.store offset=16 local.get 0 i32.load8_u offset=16)

extern "wasm" fn v_select_raw(p : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 local.get 0 v128.load local.get 0 v128.load offset=16 local.get 0 v128.load offset=32 v128.bitselect v128.store offset=48 local.get 0 i32.load offset=48)

extern "wasm" fn v_narrow_raw(p : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 local.get 0 v128.load local.get 0 v128.load offset=16 i8x16.narrow_i16x8_s v128.store offset=32 local.get 0 i32.load8_u offset=39)

pub fn v_copy(p : Int) -> Int { v_copy_raw(p) }
pub fn v_select(p : Int) -> Int { v_select_raw(p) }
pub fn v_narrow(p : Int) -> Int { v_narrow_raw(p) }
