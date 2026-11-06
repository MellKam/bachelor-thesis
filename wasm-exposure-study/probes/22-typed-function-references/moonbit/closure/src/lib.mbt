fn double(x : Int) -> Int {
  x * 2
}

fn plus100(x : Int) -> Int {
  x + 100
}

// two candidates in a mutable array, so the call cannot be resolved at compile time (as in the feature 03 probe)
let fs : Array[(Int) -> Int] = [double, plus100]

///|
pub fn apply(x : Int) -> Int {
  fs[x >> 31 & 1](x)
}
