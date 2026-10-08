(module
  (func (export "classify") (param $x i32) (result i32)
    (@metadata.code.branch_hint "\00")
    (if (result i32) (i32.lt_s (local.get $x) (i32.const 0))
      (then (i32.const -1))
      (else (i32.mul (local.get $x) (i32.const 2))))))
