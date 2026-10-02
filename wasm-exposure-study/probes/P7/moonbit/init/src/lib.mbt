let g : Ref[Int] = { val: 0 }

fn init {
  g.val = 7
}

pub fn get() -> Int {
  g.val
}
