@external("host", "base")
declare const base: i32;

// the natural attempt: a global whose initial value is computed from the imported one
export const g: i32 = base + 4 * 3;

export function get_g(): i32 {
  return g;
}
