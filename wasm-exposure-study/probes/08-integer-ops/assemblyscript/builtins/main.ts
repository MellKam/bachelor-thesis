export function i_add(a: i32, b: i32): i32 { return a + b; }
export function i_sub(a: i32, b: i32): i32 { return a - b; }
export function i_mul(a: i32, b: i32): i32 { return a * b; }
export function i_div(a: i32, b: i32): i32 { return a / b; }
export function i_rem(a: i32, b: i32): i32 { return a % b; }
export function i_clz(a: i32): i32 { return clz<i32>(a); }
export function i_ctz(a: i32): i32 { return ctz<i32>(a); }
export function i_popcnt(a: i32): i32 { return popcnt<i32>(a); }
export function i_rotl(a: i32, n: i32): i32 { return rotl<i32>(a, n); }
export function i_rotr(a: i32, n: i32): i32 { return rotr<i32>(a, n); }
