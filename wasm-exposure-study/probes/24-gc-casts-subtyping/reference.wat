(module
  (type $animal (sub (struct (field i32))))
  (type $dog (sub $animal (struct (field i32) (field i32))))
  (type $bytes (array (mut i8)))
  (func (export "gc_extra") (result i32) (local $a (ref null $animal)) (local $arr (ref null $bytes))
    (local.set $a (struct.new $dog (i32.const 1) (i32.const 3)))
    (local.set $arr (array.new $bytes (i32.const 200) (i32.const 4)))
    (i32.add
      (i32.add (struct.get $dog 1 (ref.cast (ref $dog) (local.get $a)))
               (i31.get_s (ref.i31 (i32.const 7))))
      (array.get_u $bytes (local.get $arr) (i32.const 0)))))
