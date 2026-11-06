package main

func double(x int32) int32  { return x * 2 }
func plus100(x int32) int32 { return x + 100 }

var slots = [2]func(int32) int32{double, plus100}

//go:wasmexport call_slot
func callSlot(slot int32, x int32) int32 { return slots[slot&1](x) }

func main() {}
