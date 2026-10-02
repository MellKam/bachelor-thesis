@external("host", "log")
declare function log(x: i32): void;

export function run(): void {
  log(42);
}
