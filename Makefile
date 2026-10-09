# Typst needs the vendored fonts on its font path (see fonts/README.md).
TYPST ?= typst
FLAGS  = --font-path fonts

build:
	$(TYPST) compile $(FLAGS) main-en.typ

watch:
	$(TYPST) watch $(FLAGS) main-en.typ

fonts-check:
	$(TYPST) fonts $(FLAGS)

.PHONY: build watch fonts-check
