(module
  (func (export "sat_trunc") (param f64) (result i32) (i32.trunc_sat_f64_s (local.get 0)))
  (func (export "ext8") (param i32) (result i32) (i32.extend8_s (local.get 0)))
  (func (export "ext16") (param i32) (result i32) (i32.extend16_s (local.get 0))))
