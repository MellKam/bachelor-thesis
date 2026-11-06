(module
  (memory $a 1) (memory $b 1)
  (func (export "copy_test") (result i32)
    (i32.store8 $a (i32.const 0) (i32.const 1)) (i32.store8 $a (i32.const 1) (i32.const 2))
    (i32.store8 $a (i32.const 2) (i32.const 3)) (i32.store8 $a (i32.const 3) (i32.const 4))
    (memory.copy $b $a (i32.const 0) (i32.const 0) (i32.const 4))
    (i32.add (i32.add (i32.load8_u $b (i32.const 0)) (i32.load8_u $b (i32.const 1)))
             (i32.add (i32.load8_u $b (i32.const 2)) (i32.load8_u $b (i32.const 3))))))
