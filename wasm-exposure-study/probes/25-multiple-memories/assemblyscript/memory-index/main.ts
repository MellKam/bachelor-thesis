// memory.size takes no memory index in AssemblyScript; this tries to pass one.
export function copy_test(): i32 {
  return memory.size(1);
}
