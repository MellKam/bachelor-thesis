priv struct Pair {
  a : Int
  b : Int
}

// Kept in globals so the compiler cannot optimise the allocations away.
let cell : Ref[Pair] = { val: { a: 0, b: 0 } }
let store : FixedArray[Int] = FixedArray::make(4, 0)

pub fn gc_test() -> Int {
  cell.val = { a: 2, b: 3 }
  store[0] = 10
  cell.val.a + cell.val.b + store[0]
}
