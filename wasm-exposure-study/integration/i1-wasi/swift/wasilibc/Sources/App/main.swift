// The C library of the WASI SDK, imported as the WASILibc module: read(2) and write(2) on fd 0 and 1.
import WASILibc

var buf = [UInt8](repeating: 0, count: 4096)
while true {
    let n = read(0, &buf, buf.count)
    if n <= 0 { break }
    var off = 0
    while off < n {
        let w = buf.withUnsafeBytes { write(1, $0.baseAddress! + off, n - off) }
        if w <= 0 { exit(1) }
        off += w
    }
}
