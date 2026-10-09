package main

// Go has no vector type. The only thing a program can do is write a loop over four lanes and hope the optimiser
// vectorises it once `-llvm-features=+simd128` lets LLVM use v128; nothing in the source asks for a vector instruction.

var lhs, rhs, out [4]int32

//go:wasmexport simd_add
func simdAdd(a, b int32) int32 {
	for i := range lhs {
		lhs[i] = a
		rhs[i] = b
	}
	for i := range out {
		out[i] = lhs[i] + rhs[i]
	}
	return out[0]
}

//go:wasmexport simd_shuffle
func simdShuffle(a, b int32) int32 {
	for i := range lhs {
		lhs[i] = a
		rhs[i] = b
	}
	for i := range out {
		out[i] = rhs[3-i] // lanes taken in reverse order
	}
	return out[0]
}

func main() {}
