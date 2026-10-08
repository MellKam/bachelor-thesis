(module
  (memory i64 1)
  (func (export "touch") (result i32)
    (i32.store (i64.const 16) (i32.const 42))
    (i32.load (i64.const 16))))
