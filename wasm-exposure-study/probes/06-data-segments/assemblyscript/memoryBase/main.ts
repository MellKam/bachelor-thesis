const DATA = memory.data<u8>([0x57, 0x41, 0x53, 0x4d]);
export function dataAddress(): i32 { return DATA; }

export function peek(addr: i32): i32 {
  return load<u8>(addr);
}
