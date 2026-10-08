function double(x: i32): i32 {
  return x * 2;
}

function plus100(x: i32): i32 {
  return x + 100;
}

const slots: ((x: i32) => i32)[] = [double, plus100];

export function call_slot(slot: i32, x: i32): i32 {
  return slots[slot](x);
}
