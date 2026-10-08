class Pair {
  constructor(public a: i32, public b: i32) {}
}

let cell: Pair = new Pair(0, 0);
let store: StaticArray<i32> = new StaticArray<i32>(4);

export function gc_test(): i32 {
  cell = new Pair(2, 3);
  store[0] = 10;
  return cell.a + cell.b + store[0];
}
