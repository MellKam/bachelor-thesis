# Typst needs the vendored fonts on its font path (see fonts/README.md).
TYPST ?= typst
FLAGS  = --font-path fonts

# PDF names are read from the thesis metadata (`#metadata(meta) <thesis-meta>` in each
# main-*.typ): "<author> - <English title> (<lang>).pdf". Usage: $(call meta,<file>,<field>).
meta = $(shell $(TYPST) eval $(FLAGS) 'query(<thesis-meta>).first().value.$(2)' --in $(1) 2>/dev/null | tr -d '"')
PDF_EN = $(call meta,main-en.typ,author) - $(call meta,main-en.typ,subtitle) (en).pdf
PDF_PL = $(call meta,main-pl.typ,author) - $(call meta,main-pl.typ,subtitle) (pl).pdf

# The bar charts and the diagrams are drawn by figures/render.typ and placed in the text as
# pictures, so that they survive conversion to Word. A picture is rebuilt when the chart code,
# the study data or the fonts change; the pictures are committed, so `typst compile` also works
# without make.
CHARTS = reach exposure size-wx impl-size pipeline
PICTURES = $(foreach c,$(CHARTS),figures/build/$(c)-pl.png figures/build/$(c)-en.png)
FIGURE_SOURCES = $(wildcard figures/*.typ) $(wildcard wasm-exposure-study/results/rating/*.json wasm-exposure-study/results/integration/*.json wasm-exposure-study/results/*.json)

figures: $(PICTURES)

figures/build/%.png: $(FIGURE_SOURCES)
	@mkdir -p figures/build
	$(TYPST) compile --root . $(FLAGS) --format png --ppi 300 \
	  --input chart=$(patsubst %-pl,%,$(patsubst %-en,%,$*)) --input lang=$(lastword $(subst -, ,$*)) \
	  figures/render.typ $@

build: figures
	$(TYPST) compile $(FLAGS) main-en.typ "$(PDF_EN)"

build-pl: figures
	$(TYPST) compile $(FLAGS) main-pl.typ "$(PDF_PL)"

# A PDF for conversion to Word: no footer numbers (a converter turns them into one fixed text);
# add the numbers in Word as a page-number field.
build-pl-word: figures
	$(TYPST) compile $(FLAGS) --input page-numbers=no main-pl.typ "$(PDF_PL:.pdf=) (for Word).pdf"

watch:
	$(TYPST) watch $(FLAGS) main-en.typ "$(PDF_EN)"

fonts-check:
	$(TYPST) fonts $(FLAGS)

.PHONY: figures build build-pl build-pl-word watch fonts-check
