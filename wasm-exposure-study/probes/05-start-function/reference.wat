(module
  (global $g (mut i32) (i32.const 0))
  (func $init (global.set $g (i32.const 7)))
  (start $init)
  (func (export "get") (result i32) (global.get $g)))
