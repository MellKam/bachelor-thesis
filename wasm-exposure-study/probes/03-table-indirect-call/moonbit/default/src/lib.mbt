fn double(x : Int) -> Int {
  x * 2
}

fn plus100(x : Int) -> Int {
  x + 100
}

let slots : Array[(Int) -> Int] = [double, plus100]

pub fn call_slot(slot : Int, x : Int) -> Int {
  slots[slot & 1](x)
}
