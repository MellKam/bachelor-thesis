priv suberror Boom {
  Boom(Int)
}

fn boom(x : Int) -> Int raise Boom {
  raise Boom(x)
}

pub fn roundtrip(x : Int) -> Int {
  try boom(x) catch {
    Boom(n) => n
  } noraise {
    v => v
  }
}
