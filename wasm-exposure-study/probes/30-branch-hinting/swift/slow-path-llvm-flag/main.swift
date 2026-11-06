// As `slow-path`, with the LLVM option that this toolchain's backend lists as "Enable branch hint".
@_expose(wasm, "classify") @_cdecl("classify")
func classify(_ x: Int32) -> Int32 {
    if _slowPath(x < 0) { return -1 }
    return x &* 2
}
