#![feature(asm_experimental_arch)]
#![no_std]

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

core::arch::global_asm!(r#"
.tabletype t, funcref, 1
t:

.section .text.f,"",@
.globl f
.export_name f, f
f:
  .functype f () -> ()
  end_function

.section .text.table_ops,"",@
.globl table_ops
.export_name table_ops, table_ops
table_ops:
  .functype table_ops (i32) -> (i32)
  ref.null_func
  local.get 0
  table.grow t
  drop
  i32.const 1
  ref.func f
  table.set t
  table.size t
  i32.const 2
  table.get t
  ref.is_null
  i32.const 100
  i32.mul
  i32.add
  i32.const 1
  table.get t
  ref.is_null
  i32.eqz
  i32.const 1000
  i32.mul
  i32.add
  end_function
"#);
