(module
  (type $f (func (param i32) (result i32)))
  (elem declare func $double)
  (func $double (type $f) (i32.mul (local.get 0) (i32.const 2)))
  (func (export "apply") (param i32) (result i32)
    (call_ref $f (local.get 0) (ref.func $double))))
