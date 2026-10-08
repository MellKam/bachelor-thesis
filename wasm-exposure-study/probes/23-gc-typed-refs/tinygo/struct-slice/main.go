package main

type pair struct{ a, b int32 }

var cell *pair
var store []int32

//go:wasmexport gc_test
func gcTest() int32 {
	cell = &pair{2, 3}
	store = make([]int32, 4)
	store[0] = 10
	return cell.a + cell.b + store[0]
}

func main() {}
