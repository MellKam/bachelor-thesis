pub fn bulk_test(n : Int) -> Int {
  let a : Array[Byte] = Array::make(512, b'\x00')
  a.fill(b'\x05', start=0, end=n)
  a.blit_to(a, len=n, src_offset=0, dst_offset=256)
  let mut s = 0
  for i in 0..<n {
    s += a[256 + i].to_int()
  }
  s
}
