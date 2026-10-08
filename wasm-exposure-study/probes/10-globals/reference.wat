(module
  (import "host" "base" (global $base i32))
  (global $counter (export "counter") (mut i32) (i32.const 0))
  (func (export "bump") (result i32)
    (global.set $counter (i32.add (global.get $base) (i32.const 1)))
    (global.get $counter)))
