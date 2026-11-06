(module
  (type $f (func (param i32) (result i32)))
  (table 2 funcref)
  (elem (i32.const 0) $double $plus100)
  (func $double (type $f) (i32.mul (local.get 0) (i32.const 2)))
  (func $plus100 (type $f) (i32.add (local.get 0) (i32.const 100)))
  (func (export "call_slot") (param $slot i32) (param $x i32) (result i32)
    (call_indirect (type $f) (local.get $x) (local.get $slot))))
