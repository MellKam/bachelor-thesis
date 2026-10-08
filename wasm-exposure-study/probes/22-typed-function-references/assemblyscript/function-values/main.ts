function double(x: i32): i32 {
  return x * 2;
}

let f: (x: i32) => i32 = double;

export function apply(x: i32): i32 {
  return f(x);
}
