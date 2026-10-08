(module
  (memory (export "mem") 1)
  (data $d "WASM")
  (func (export "load") (param $dst i32)
    (memory.init $d (local.get $dst) (i32.const 0) (i32.const 4))
    (data.drop $d))
  (func (export "peek") (param i32) (result i32) (i32.load8_u (local.get 0))))
