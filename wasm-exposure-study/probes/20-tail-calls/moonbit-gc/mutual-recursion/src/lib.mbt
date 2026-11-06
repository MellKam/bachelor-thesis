fn a(n : Int, acc : Int) -> Int {
  if n == 0 { acc } else { b(n - 1, acc + 1) }
}

fn b(n : Int, acc : Int) -> Int {
  if n == 0 { acc } else { a(n - 1, acc + 1) }
}

pub fn count(n : Int, acc : Int) -> Int { a(n, acc) }
