(module
  (type $f (func (param i32) (result i32)))
  (table $a 1 funcref) (table $b 1 funcref)
  (elem (table $a) (i32.const 0) func $add1)
  (elem (table $b) (i32.const 0) func $add100)
  (func $add1 (type $f) (i32.add (local.get 0) (i32.const 1)))
  (func $add100 (type $f) (i32.add (local.get 0) (i32.const 100)))
  (func (export "call_a") (param i32) (result i32) (call_indirect $a (type $f) (local.get 0) (i32.const 0)))
  (func (export "call_b") (param i32) (result i32) (call_indirect $b (type $f) (local.get 0) (i32.const 0))))
