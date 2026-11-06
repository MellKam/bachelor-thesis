package main

import "syscall/js"

func isWS(c byte) bool { return c == ' ' || c == '\t' || c == '\n' || c == '\r' }

func analyse(this js.Value, args []js.Value) any {
	text := args[0].String()
	var words int
	best, bestAt, i := 0, 0, 0
	for i < len(text) {
		for i < len(text) && isWS(text[i]) {
			i++
		}
		start := i
		for i < len(text) && !isWS(text[i]) {
			i++
		}
		if i > start {
			words++
			if i-start > best {
				best, bestAt = i-start, start
			}
		}
	}
	return map[string]any{"words": words, "bytes": len(text), "longest": text[bestAt : bestAt+best]}
}

func main() {
	js.Global().Set("analyse", js.FuncOf(analyse))
	select {} // keep the program alive so the callback stays registered
}
