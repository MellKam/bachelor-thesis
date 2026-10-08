///|
fn fill(buf : FixedArray[Byte], start : Int, v : Int) -> Unit {
  for i in 0..<16 {
    buf[start + i] = v.to_byte()
  }
}

///|
fn set16(buf : FixedArray[Byte], off : Int, v : Int) -> Unit {
  buf[off] = (v & 0xff).to_byte()
  buf[off + 1] = ((v >> 8) & 0xff).to_byte()
}

// MoonBit has no raw addresses: a vector is loaded from a FixedArray[Byte] the program owns, not from memory the host filled,
// so the argument `p` is unused. The checker still sees which Wasm instructions were emitted.
///|
pub fn v_copy(p : Int) -> Int {
  ignore(p)
  let buf : FixedArray[Byte] = FixedArray::make(64, b'\x00')
  for i in 0..<16 {
    buf[i] = (i + 1).to_byte()
  }
  @v128.v128_store(buf, 16, @v128.v128_load(buf, 0))
  buf[16].to_int()
}

///|
pub fn v_select(p : Int) -> Int {
  ignore(p)
  let buf : FixedArray[Byte] = FixedArray::make(64, b'\x00')
  fill(buf, 0, 0x11)
  fill(buf, 16, 0x22)
  fill(buf, 32, 0xf0)
  let r = @v128.v128_bitselect(@v128.v128_load(buf, 0), @v128.v128_load(buf, 16), @v128.v128_load(buf, 32))
  @v128.v128_store(buf, 48, r)
  @v128.i32x4_extract_lane(r, 0).reinterpret_as_int()
}

///|
pub fn v_narrow(p : Int) -> Int {
  ignore(p)
  let buf : FixedArray[Byte] = FixedArray::make(64, b'\x00')
  let a = [1, 2, 3, 4, 5, 6, 7, 300]
  let b = [-1, -2, -3, -4, -5, -6, -7, -300]
  for i in 0..<8 {
    set16(buf, i * 2, a[i])
    set16(buf, 16 + i * 2, b[i])
  }
  let r = @v128.i8x16_narrow_i16x8_s(@v128.v128_load(buf, 0), @v128.v128_load(buf, 16))
  @v128.v128_store(buf, 32, r)
  buf[39].to_int()
}
