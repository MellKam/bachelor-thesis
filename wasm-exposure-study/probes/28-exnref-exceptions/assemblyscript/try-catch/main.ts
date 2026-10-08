export function rethrow_test(x: i32): i32 {
  try {
    try {
      throw new Error("x");
    } catch (e) {
      throw e; // throw the caught exception again
    }
  } catch (e) {
    return x;
  }
  return -1;
}
