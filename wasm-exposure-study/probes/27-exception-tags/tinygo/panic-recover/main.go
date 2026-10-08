package main

func boom(x int32) {
	panic(x)
}

//go:wasmexport roundtrip
func roundtrip(x int32) (r int32) {
	defer func() {
		if v := recover(); v != nil {
			r = v.(int32)
		}
	}()
	boom(x)
	return -1
}

func main() {}
