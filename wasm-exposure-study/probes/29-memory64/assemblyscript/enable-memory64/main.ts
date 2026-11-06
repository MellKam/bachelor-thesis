export function touch(): i32 {
  store<i32>(16, 42);
  return load<i32>(16);
}
