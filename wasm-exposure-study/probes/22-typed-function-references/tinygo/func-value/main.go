package main

func double(x int32) int32 { return x * 2 }

var f = double

//go:wasmexport apply
func apply(x int32) int32 { return f(x) }

func main() {}
