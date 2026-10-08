pub fn i_add(a : Int, b : Int) -> Int { a + b }
pub fn i_sub(a : Int, b : Int) -> Int { a - b }
pub fn i_mul(a : Int, b : Int) -> Int { a * b }
pub fn i_div(a : Int, b : Int) -> Int { a / b }
pub fn i_rem(a : Int, b : Int) -> Int { a % b }
pub fn i_clz(a : Int) -> Int { a.clz() }
pub fn i_ctz(a : Int) -> Int { a.ctz() }
pub fn i_popcnt(a : Int) -> Int { a.popcnt() }
pub fn i_rotl(a : Int, n : Int) -> Int { (a << n) | (a.reinterpret_as_uint() >> (32 - n)).reinterpret_as_int() }
pub fn i_rotr(a : Int, n : Int) -> Int { (a.reinterpret_as_uint() >> n).reinterpret_as_int() | (a << (32 - n)) }
