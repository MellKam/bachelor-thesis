package main

import "math/bits"

//go:wasmexport i_add
func iAdd(a, b int32) int32 { return a + b }

//go:wasmexport i_sub
func iSub(a, b int32) int32 { return a - b }

//go:wasmexport i_mul
func iMul(a, b int32) int32 { return a * b }

//go:wasmexport i_div
func iDiv(a, b int32) int32 { return a / b }

//go:wasmexport i_rem
func iRem(a, b int32) int32 { return a % b }

//go:wasmexport i_clz
func iClz(a int32) int32 { return int32(bits.LeadingZeros32(uint32(a))) }

//go:wasmexport i_ctz
func iCtz(a int32) int32 { return int32(bits.TrailingZeros32(uint32(a))) }

//go:wasmexport i_popcnt
func iPopcnt(a int32) int32 { return int32(bits.OnesCount32(uint32(a))) }

//go:wasmexport i_rotl
func iRotl(a, n int32) int32 { return int32(bits.RotateLeft32(uint32(a), int(n))) }

//go:wasmexport i_rotr
func iRotr(a, n int32) int32 { return int32(bits.RotateLeft32(uint32(a), -int(n))) }

func main() {}
