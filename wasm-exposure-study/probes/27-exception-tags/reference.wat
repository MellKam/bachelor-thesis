(module
  (tag $t (param i32))
  (func (export "roundtrip") (param i32) (result i32)
    (block $h (result i32)
      (try_table (catch $t $h) (throw $t (local.get 0)))
      (unreachable))))
