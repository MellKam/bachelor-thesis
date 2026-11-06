memory.data<u8>([0x57, 0x41, 0x53, 0x4d]); // the segment to copy from on demand

function copyIn(dst: i32): void {
  memory.init(0, 0, dst, 4); // memory.init from segment 0
  memory.drop(0);
}
export { copyIn as load };

export function peek(addr: i32): i32 {
  return i32.load8_u(addr);
}
