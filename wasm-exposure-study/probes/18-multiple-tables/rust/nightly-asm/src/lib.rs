#![feature(asm_experimental_arch)]
#![no_std]
#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

core::arch::global_asm!(r#"
.tabletype table_a, funcref, 1
table_a:
.tabletype table_b, funcref, 1
table_b:

.section .text.add1,"",@
.globl add1
.export_name add1, add1
add1:
  .functype add1 (i32) -> (i32)
  local.get 0
  i32.const 1
  i32.add
  end_function

.section .text.add100,"",@
.globl add100
.export_name add100, add100
add100:
  .functype add100 (i32) -> (i32)
  local.get 0
  i32.const 100
  i32.add
  end_function

.section .text.call_a,"",@
.globl call_a
.export_name call_a, call_a
call_a:
  .functype call_a (i32) -> (i32)
  i32.const 0
  ref.func add1
  table.set table_a
  local.get 0
  i32.const 0
  call_indirect table_a, (i32) -> (i32)
  end_function

.section .text.call_b,"",@
.globl call_b
.export_name call_b, call_b
call_b:
  .functype call_b (i32) -> (i32)
  i32.const 0
  ref.func add100
  table.set table_b
  local.get 0
  i32.const 0
  call_indirect table_b, (i32) -> (i32)
  end_function
"#);
