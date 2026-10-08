let counter : Ref[Int] = { val: 0 }

pub fn bump() -> Int {
  counter.val = counter.val + 1
  counter.val
}
