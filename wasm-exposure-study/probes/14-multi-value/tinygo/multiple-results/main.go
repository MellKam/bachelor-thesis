package main

//go:wasmexport divmod
func divmod(a, b uint32) (uint32, uint32) { return a / b, a % b }

func main() {}
