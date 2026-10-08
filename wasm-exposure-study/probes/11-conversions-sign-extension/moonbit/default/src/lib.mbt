pub fn sat_trunc(x : Double) -> Int { x.to_int() }
pub fn ext8(x : Int) -> Int { (x << 24) >> 24 }
pub fn ext16(x : Int) -> Int { (x << 16) >> 16 }
