#![feature(float_minimum_maximum)]

#[unsafe(no_mangle)] pub extern "C" fn f_sqrt(x: f64) -> f64 { x.sqrt() }
#[unsafe(no_mangle)] pub extern "C" fn f_min(x: f64, y: f64) -> f64 { x.minimum(y) }
#[unsafe(no_mangle)] pub extern "C" fn f_max(x: f64, y: f64) -> f64 { x.maximum(y) }
#[unsafe(no_mangle)] pub extern "C" fn f_ceil(x: f64) -> f64 { x.ceil() }
#[unsafe(no_mangle)] pub extern "C" fn f_floor(x: f64) -> f64 { x.floor() }
#[unsafe(no_mangle)] pub extern "C" fn f_trunc(x: f64) -> f64 { x.trunc() }
#[unsafe(no_mangle)] pub extern "C" fn f_nearest(x: f64) -> f64 { x.round_ties_even() }
#[unsafe(no_mangle)] pub extern "C" fn f_copysign(x: f64, y: f64) -> f64 { x.copysign(y) }
#[unsafe(no_mangle)] pub extern "C" fn f_abs(x: f64) -> f64 { x.abs() }
