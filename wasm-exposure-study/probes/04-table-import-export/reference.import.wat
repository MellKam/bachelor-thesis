(module
  (type $f (func (param i32) (result i32)))
  (import "host" "tbl" (table 2 8 funcref))
  (elem (i32.const 0) $double)
  (func $double (type $f) (i32.mul (local.get 0) (i32.const 2)))
  (func (export "call_slot") (param $slot i32) (param $x i32) (result i32)
    (call_indirect (type $f) (local.get $x) (local.get $slot))))
