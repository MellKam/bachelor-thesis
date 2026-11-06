// _slowPath is the stdlib's unlikely-branch hint (llvm.expect).
@_expose(wasm, "classify") @_cdecl("classify")
func classify(_ x: Int32) -> Int32 {
    if _slowPath(x < 0) { return -1 }
    return x &* 2
}
