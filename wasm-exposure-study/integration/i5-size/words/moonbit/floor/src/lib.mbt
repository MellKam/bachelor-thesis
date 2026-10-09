// `words`, floor ABI: export memory, alloc(len) -> ptr, analyse(ptr, len) -> ptr to { words, bytes, longest_ptr, longest_len }.
// MoonBit has no raw memory: loads and stores are inline Wasm. The input buffers live from 1 MiB up; the record is at 1024.
extern "wasm" fn load8(addr : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 i32.load8_u)

extern "wasm" fn store32(addr : Int, v : Int) -> Unit =
  #|(func (param i32 i32) local.get 0 local.get 1 i32.store)

extern "wasm" fn mem_pages() -> Int =
  #|(func (result i32) memory.size)

extern "wasm" fn mem_grow(n : Int) -> Int =
  #|(func (param i32) (result i32) local.get 0 memory.grow)

let heap_base : Int = 1048576

let top : Ref[Int] = { val: 0 }

pub fn alloc(len : Int) -> Int {
  let p = heap_base + top.val
  top.val = top.val + (len + 7) / 8 * 8
  let need = (heap_base + top.val + 65535) / 65536
  if mem_pages() < need {
    ignore(mem_grow(need - mem_pages()))
  }
  p
}

fn is_ws(c : Int) -> Bool {
  c == 32 || c == 9 || c == 10 || c == 13
}

pub fn analyse(ptr : Int, len : Int) -> Int {
  let mut words = 0
  let mut best = 0
  let mut best_at = 0
  let mut i = 0
  while i < len {
    while i < len && is_ws(load8(ptr + i)) {
      i = i + 1
    }
    let start = i
    while i < len && not(is_ws(load8(ptr + i))) {
      i = i + 1
    }
    if i > start {
      words = words + 1
      if i - start > best {
        best = i - start
        best_at = start
      }
    }
  }
  top.val = 0
  store32(1024, words)
  store32(1028, len)
  store32(1032, ptr + best_at)
  store32(1036, best)
  1024
}
