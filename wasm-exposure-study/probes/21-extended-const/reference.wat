(module
  (import "host" "base" (global $base i32))
  (global $g i32 (i32.add (global.get $base) (i32.mul (i32.const 4) (i32.const 3))))
  (func (export "get_g") (result i32) (global.get $g)))
