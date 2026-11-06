(module
  (func (export "divmod") (param i32 i32) (result i32 i32)
    (i32.div_u (local.get 0) (local.get 1)) (i32.rem_u (local.get 0) (local.get 1))))
