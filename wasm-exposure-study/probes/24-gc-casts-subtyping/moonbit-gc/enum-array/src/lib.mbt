enum Animal {
  Cat(Int)
  Dog(Int, Int)
}

///|
pub fn gc_extra() -> Int {
  let a : Animal = Dog(1, 3)
  let extra = match a {
    Dog(_, e) => e
    Cat(_) => 0
  }
  let bytes : FixedArray[Byte] = FixedArray::make(4, b'\x00')
  bytes[0] = (200).to_byte()
  extra + 7 + bytes[0].to_int()
}
