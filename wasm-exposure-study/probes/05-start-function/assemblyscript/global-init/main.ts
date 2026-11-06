function seven(): i32 {
  return 7;
}

// A non-constant global initialiser: AssemblyScript compiles top-level code into the module's start function.
let g: i32 = seven();

export function get(): i32 {
  return g;
}
