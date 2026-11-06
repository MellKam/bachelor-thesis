@external("wasi_snapshot_preview1", "fd_read")
declare function fd_read(fd: i32, iovs: i32, iovs_len: i32, nread: i32): i32;

@external("wasi_snapshot_preview1", "fd_write")
declare function fd_write(fd: i32, iovs: i32, iovs_len: i32, nwritten: i32): i32;

const BUF = memory.data(4096);
const IOV = memory.data(8);
const NUM = memory.data(4);

export function _start(): void {
  while (true) {
    store<i32>(IOV, <i32>BUF);
    store<i32>(IOV, 4096, 4);
    if (fd_read(0, <i32>IOV, 1, <i32>NUM) != 0) return;
    const n = load<i32>(NUM);
    if (n == 0) return;
    store<i32>(IOV, n, 4);
    if (fd_write(1, <i32>IOV, 1, <i32>NUM) != 0) return;
  }
}
