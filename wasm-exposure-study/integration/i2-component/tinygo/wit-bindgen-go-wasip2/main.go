package main

import (
	words "words/internal/study/words/words"
)

func isWS(c byte) bool { return c == ' ' || c == '\t' || c == '\n' || c == '\r' }

func init() {
	words.Exports.Analyse = func(text string) (r words.Stats) {
		best, bestAt := 0, 0
		i := 0
		for i < len(text) {
			for i < len(text) && isWS(text[i]) {
				i++
			}
			start := i
			for i < len(text) && !isWS(text[i]) {
				i++
			}
			if i > start {
				r.Words++
				if i-start > best {
					best, bestAt = i-start, start
				}
			}
		}
		r.Bytes = uint32(len(text))
		r.Longest = text[bestAt : bestAt+best]
		return
	}
}

func main() {}
