package main

import "math"

//go:wasmexport f_sqrt
func fSqrt(x float64) float64 { return math.Sqrt(x) }

//go:wasmexport f_min
func fMin(x, y float64) float64 { return min(x, y) }

//go:wasmexport f_max
func fMax(x, y float64) float64 { return max(x, y) }

//go:wasmexport f_ceil
func fCeil(x float64) float64 { return math.Ceil(x) }

//go:wasmexport f_floor
func fFloor(x float64) float64 { return math.Floor(x) }

//go:wasmexport f_trunc
func fTrunc(x float64) float64 { return math.Trunc(x) }

//go:wasmexport f_nearest
func fNearest(x float64) float64 { return math.RoundToEven(x) }

//go:wasmexport f_copysign
func fCopysign(x, y float64) float64 { return math.Copysign(x, y) }

//go:wasmexport f_abs
func fAbs(x float64) float64 { return math.Abs(x) }

func main() {}
