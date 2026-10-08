(module
  (func $count (export "count") (param $n i32) (param $acc i32) (result i32)
    (if (result i32) (i32.eqz (local.get $n))
      (then (local.get $acc))
      (else (return_call $count (i32.sub (local.get $n) (i32.const 1)) (i32.add (local.get $acc) (i32.const 1)))))))
