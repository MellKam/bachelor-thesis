// Vectors come from and go to linear memory, so the optimiser cannot fold them into scalar code.
export function v_copy(p: usize): i32 {
  v128.store(p + 16, v128.load(p));
  return i32.load8_u(p + 16);
}

export function v_select(p: usize): i32 {
  const r = v128.bitselect(v128.load(p), v128.load(p + 16), v128.load(p + 32));
  v128.store(p + 48, r);
  return v128.extract_lane<i32>(r, 0);
}

export function v_narrow(p: usize): i32 {
  v128.store(p + 32, v128.narrow<i16>(v128.load(p), v128.load(p + 16)));
  return i32.load8_u(p + 39);
}
