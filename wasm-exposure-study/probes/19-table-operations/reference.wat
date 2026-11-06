(module
  (table $t 1 funcref)
  (elem declare func $f)
  (func $f)
  (func (export "table_ops") (param $n i32) (result i32)
    (drop (table.grow $t (ref.null func) (local.get $n)))
    (table.set $t (i32.const 1) (ref.func $f))
    (i32.add
      (i32.add (table.size $t)
               (select (i32.const 100) (i32.const 0) (ref.is_null (table.get $t (i32.const 2)))))
      (select (i32.const 0) (i32.const 1000) (ref.is_null (table.get $t (i32.const 1)))))))
