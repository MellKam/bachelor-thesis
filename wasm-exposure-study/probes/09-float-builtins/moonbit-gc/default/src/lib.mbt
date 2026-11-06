pub fn f_sqrt(x : Double) -> Double { x.sqrt() }
pub fn f_min(x : Double, y : Double) -> Double { x.min(y) }
pub fn f_max(x : Double, y : Double) -> Double { x.max(y) }
pub fn f_ceil(x : Double) -> Double { x.ceil() }
pub fn f_floor(x : Double) -> Double { x.floor() }
pub fn f_trunc(x : Double) -> Double { x.trunc() }
pub fn f_nearest(x : Double) -> Double { x.round() }
pub fn f_copysign(x : Double, y : Double) -> Double { if y < 0.0 { -x.abs() } else { x.abs() } }
pub fn f_abs(x : Double) -> Double { x.abs() }
