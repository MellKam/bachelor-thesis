// No multi-value in the language: the closest thing is returning an array.
export function divmod(a: u32, b: u32): u32[] {
  return [a / b, a % b];
}
