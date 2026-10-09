// The result type comes from a C header, so Swift lowers it with the C ABI of the imported struct; clang is told to use the experimental multi-value ABI that makes the C probe return two values.
import PairC

@_expose(wasm, "divmod") @_cdecl("divmod")
func divmod(_ a: UInt32, _ b: UInt32) -> pair_t { pair_t(q: a / b, r: a % b) }
