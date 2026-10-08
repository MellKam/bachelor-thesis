(module
  (memory (export "memory") 1)
  (data (i32.const 1024) "WASM")
  (func (export "peek") (param i32) (result i32) (i32.load8_u (local.get 0))))
