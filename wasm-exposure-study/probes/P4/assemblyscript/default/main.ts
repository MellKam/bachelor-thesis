@external("host", "base")
declare const base: i32;

export let counter: i32 = 0;

export function bump(): i32 {
  counter = base + 1;
  return counter;
}
