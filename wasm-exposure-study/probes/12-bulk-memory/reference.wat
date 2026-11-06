(module
  (memory 1)
  (func (export "bulk_test") (param $n i32) (result i32) (local $i i32) (local $s i32)
    (memory.fill (i32.const 0) (i32.const 5) (local.get $n))
    (memory.copy (i32.const 256) (i32.const 0) (local.get $n))
    (block $done (loop $l
      (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $s (i32.add (local.get $s) (i32.load8_u offset=256 (local.get $i))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $l)))
    (local.get $s)))
