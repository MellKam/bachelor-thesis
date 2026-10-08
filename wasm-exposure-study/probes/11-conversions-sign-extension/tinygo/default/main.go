package main

//go:wasmexport sat_trunc
func satTrunc(x float64) int32 { return int32(x) }

//go:wasmexport ext8
func ext8(x int32) int32 { return int32(int8(x)) }

//go:wasmexport ext16
func ext16(x int32) int32 { return int32(int16(x)) }

func main() {}
