(module
  (type $pair (struct (field i32) (field i32)))
  (type $ints (array (mut i32)))
  (func (export "gc_test") (result i32) (local $p (ref $pair)) (local $a (ref $ints))
    (local.set $p (struct.new $pair (i32.const 2) (i32.const 3)))
    (local.set $a (array.new_default $ints (i32.const 4)))
    (array.set $ints (local.get $a) (i32.const 0) (i32.const 10))
    (i32.add (i32.add (struct.get $pair 0 (local.get $p)) (struct.get $pair 1 (local.get $p)))
             (array.get $ints (local.get $a) (i32.const 0)))))
