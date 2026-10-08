package main

//go:wasmimport host log
func hostLog(x int32)

//go:wasmexport run
func run() { hostLog(42) }

func main() {}
