// Shared thesis template (classic theme). Everything about page layout,
// typography and front matter lives here, so a university template can be matched
// later by editing this one file (and `meta` in main-*.typ), never the chapters.
//
// Design: plain black on white, one column, one serif family for text and
// headings. Liberation Serif is metric-compatible with Times New Roman, so line
// and page breaks match what Word would produce. No rules, no accent colour;
// hierarchy comes from size and weight alone. Colour is reserved for chart data.
//
// An earlier sans-heading theme is kept in `template-modern.typ`; to try it, change
// the `#import` of the template in main-en.typ and the chapter files.
//
// Fonts: vendored in fonts/ (see fonts/README.md); build with `make build`.

// ---------------------------------------------------------------------------
// Tunable layout parameters — WSZiB-ANS thesis standard
// ---------------------------------------------------------------------------
#let layout = (
  paper: "a4",
  margin: (left: 2.5cm, right: 2.5cm, top: 2.5cm, bottom: 2.5cm),  // 2.5cm on all sides per WSZiB standard
  serif: ("Liberation Serif", "Libertinus Serif"),
  sans: ("Liberation Serif", "Libertinus Serif"),  // WSZiB requires Times New Roman (Liberation Serif is metric-compatible) across the entire document
  mono: ("Liberation Mono", "DejaVu Sans Mono"),
  size: 12pt,
  leading: 1.07em,   // 1.5 line spacing as Word sets it for Times New Roman 12 pt (about 20.7 pt between baselines)
  spacing: 1.0em,    // block formatting without extra gap between paragraphs
  indent: 1.25cm,    // automatic first-line paragraph indent
)

#let ink = black
#let muted = luma(90)
#let hairline = luma(200)
#let sans = layout.serif

// Default source note placed below every figure/table/listing if not overridden.
#let default-source = state("figure-source", [opracowanie własne.])
#let with-source(src, body) = {
  default-source.update(src)
  body
  default-source.update([opracowanie własne.])
}

// Strip a trailing period from a caption or heading body if present.
#let strip-trailing-dot(body) = {
  if body == none { return none }
  if body.func() == text {
    let t = body.text
    if t.ends-with(".") {
      return text(t.slice(0, -1))
    }
    return body
  }
  if body.has("children") {
    let ch = body.children
    if ch.len() > 0 {
      let last = ch.last()
      if last.func() == text and last.text.ends-with(".") {
        let trimmed = last.text.slice(0, -1)
        let new-ch = ch.slice(0, -1) + (if trimmed.len() > 0 { (text(trimmed),) } else { () })
        return new-ch.join()
      }
    }
  }
  body
}

// Drafting aid: `#todo[...]` shows a visible marker. Set to false for a clean PDF.
#let show-todos = true
#let todo(body) = if show-todos {
  box(
    stroke: (paint: muted, thickness: 0.6pt, dash: "dashed"),
    inset: (x: 4pt, y: 2pt),
    radius: 2pt,
    text(size: 0.8em)[*TODO* #body],
  )
}

// Full-grid table with 10pt text and shaded bold header row per WSZiB standard (Rysunek 4).
#let booktable(..args) = {
  let named = args.named()
  let orig-align = named.at("align", default: left)
  let _ = named.remove("align")
  let cell-align = if type(orig-align) == array {
    orig-align.map(a => a + horizon)
  } else if type(orig-align) == function {
    (x, y) => orig-align(x, y) + horizon
  } else {
    orig-align + horizon
  }
  let pos = args.pos().filter(x => type(x) != content or x.func() != table.hline)
  show table.cell.where(y: 0): set text(weight: "bold")
  show table.cell.where(y: 0): set align(center + horizon)
  set text(font: layout.serif, size: 10pt)
  set par(justify: false, first-line-indent: 0pt, leading: 0.55em)
  table(
    stroke: 0.5pt + black,
    fill: (x, y) => if y == 0 { luma(230) } else { none },
    align: cell-align,
    inset: (x: 6pt, y: 5pt),
    ..named,
    ..pos,
  )
}

// ---------------------------------------------------------------------------
// Whole-document rules
// ---------------------------------------------------------------------------
#let thesis(meta: (:), body) = {
  set document(title: meta.title, author: meta.author)
  set text(
    font: layout.serif,
    size: layout.size,
    lang: meta.at("lang", default: "pl"),
  )
  set par(
    justify: true,
    linebreaks: "optimized",
    leading: layout.leading,
    spacing: layout.spacing,
    first-line-indent: (amount: layout.indent, all: true),
  )

  // Page: continuous numbering in the footer, centered; first (title) page has no number.
  set page(
    paper: layout.paper,
    margin: layout.margin,
    numbering: "1",
    footer: context {
      // `--input page-numbers=no` leaves the footer empty, for a PDF that is converted to Word,
      // where the numbers are added as a real page-number field (see Makefile, build-pl-word).
      if sys.inputs.at("page-numbers", default: "yes") == "no" { return }
      let p = counter(page).get().first()
      if p <= 1 or here().page-numbering() == none { return }
      align(center, text(font: layout.serif, size: 10pt, numbering(here().page-numbering(), p)))
    },
  )

  // Headings: Times New Roman / Liberation Serif, bold, left-aligned, Arabic numbers,
  // 16pt for chapters, 14pt for subchapters, double line spacing, no trailing period.
  set heading(numbering: "1.1", supplement: [Rozdział])
  show heading: set text(font: layout.serif, hyphenate: false)
  show heading: set par(justify: false, first-line-indent: 0pt, leading: 1.3em)
  let heading-block(it, size, above, below, style: "normal") = block(above: above, below: below, sticky: true, {
    set text(font: layout.serif, size: size, weight: "bold", style: style)
    if it.numbering != none {
      counter(heading).display(it.numbering)
      h(0.6em)
    }
    strip-trailing-dot(it.body)
  })
  show heading.where(level: 2): it => heading-block(it, 14pt, 2.0em, 1.2em)
  show heading.where(level: 3): it => heading-block(it, 14pt, 1.8em, 1.0em)
  show heading.where(level: 4): it => heading-block(it, 12pt, 1.5em, 0.8em, style: "italic")

  // Chapters: start on a new page, 16pt bold at the left margin.
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    heading-block(it, 16pt, 0pt, 1.6em)
  }

  // Figures, tables and listings: continuous Arabic numbering (1, 2, ...),
  // caption on top (10pt bold, centered, no period at the end),
  // object centered, source below (10pt, justified), single-line gap around object.
  set figure(numbering: "1", gap: 1em)
  show figure.where(kind: table): set figure(supplement: [Tabela])
  show figure.where(kind: image): set figure(supplement: [Rysunek])
  show figure.where(kind: "chart"): set figure(supplement: [Wykres])
  show figure.where(kind: raw): set figure(supplement: [Listing])
  show figure: set figure.caption(position: top)
  show figure.caption: it => align(center, block(width: 100%, {
    set text(font: layout.serif, size: 10pt, weight: "bold")
    set par(justify: false, first-line-indent: 0pt, leading: 0.65em)
    it.supplement
    [ ]
    it.counter.display(it.numbering)
    [. ]
    strip-trailing-dot(it.body)
  }))
  show figure: it => block(
    width: 100%,
    above: 2.0em,
    below: 2.0em,
    breakable: false,
    {
      if it.caption != none {
        it.caption
        v(0.8em, weak: true)
      }
      align(center, {
        set text(font: layout.serif, size: 10pt)
        it.body
      })
      v(0.8em, weak: true)
      align(left, block(width: 100%, {
        set text(font: layout.serif, size: 10pt, weight: "regular")
        set par(justify: true, first-line-indent: 0pt, leading: 0.65em)
        context [Źródło: #default-source.get()]
      }))
    },
  )
  set table(stroke: 0.5pt + black)
  show table: set text(font: layout.serif, size: 10pt)
  show table: set par(justify: false, first-line-indent: 0pt)

  // Footnotes: 10 pt, single line spacing, numbered continuously (WSZiB-ANS standard).
  show footnote.entry: it => {
    set text(font: layout.serif, size: 10pt)
    set par(justify: true, first-line-indent: 0pt, leading: 0.55em, spacing: 0.4em)
    it
  }
  set footnote.entry(separator: line(length: 30%, stroke: 0.5pt + black), gap: 0.5em, clearance: 1em)

  // Code
  set raw(align: left)
  show raw: set text(font: layout.mono, size: 0.85em)
  // Custom wx/wat grammars, each scoped to its own `lang` tag so neither
  // overrides the built-in highlighting used for other languages.
  show raw.where(lang: "wx"): set raw(syntaxes: "wx.sublime-syntax")
  show raw.where(lang: "wat"): set raw(syntaxes: "wat.sublime-syntax")
  show raw.where(block: false): it => box(fill: luma(240), outset: (x: 1.5pt, y: 1.5pt), radius: 2pt, it)
  show raw.where(block: true): it => block(
    width: 100%,
    fill: luma(248),
    stroke: 0.5pt + hairline,
    inset: (x: 8pt, y: 8pt),
    {
      set text(size: 9pt)
      set align(left)
      set par(first-line-indent: 0pt, leading: 0.55em)
      it
    },
  )

  // Links stay in ink: external addresses are underlined, internal references are plain.
  show link: it => if type(it.dest) == str {
    underline(offset: 2pt, stroke: 0.4pt + muted, it)
  } else {
    it
  }
  show ref: it => {
    let el = it.element
    if el != none and el.func() == heading and el.level == 1 and el.numbering != none {
      link(el.location())[Rozdział #numbering(el.numbering, ..counter(heading).at(el.location()))]
    } else { it }
  }

  // Multilevel bulleted list markers per Rysunek 3 (bullet, open circle, small square)
  set list(marker: ([•], [◦], [▪]), indent: 1.25cm, body-indent: 0.5em, spacing: 0.8em)
  set enum(indent: 1.25cm, body-indent: 0.5em, spacing: 0.8em)

  body
}

// ---------------------------------------------------------------------------
// Title page and structural sections (WSZiB-ANS Rysunek 1 & Rysunek 2)
// ---------------------------------------------------------------------------
#let title-page(meta) = {
  set page(footer: none)
  set text(font: layout.serif)
  set par(justify: false, first-line-indent: 0pt, leading: 0.55em, spacing: 0pt)

  align(center, {
    // Czcionka Times New Roman 18 pkt, pogrubienie, wyśrodkowanie
    text(size: 18pt, weight: "bold", upper(meta.university))
    parbreak()

    // 16 pkt, pogrubienie, wyśrodkowanie, odstęp przed akapitem 24 pkt
    v(24pt)
    text(size: 16pt, weight: "bold", meta.faculty)
    parbreak()

    // 14 pkt, pogrubienie, wyśrodkowanie, odstęp przed akapitem 18 pkt
    v(18pt)
    text(size: 14pt, weight: "bold")[KIERUNEK: #meta.at("field", default: meta.at("programme", default: ""))]
    parbreak()

    // 12 pkt, pogrubienie, wyśrodkowanie, odstęp przed akapitem 12 pkt
    if meta.at("scope", default: none) != none {
      v(12pt)
      text(size: 12pt, weight: "bold")[ZAKRES: #meta.scope]
      parbreak()
    }

    // 16 pkt, wyśrodkowanie (bez pogrubienia), odstęp przed akapitem 90 pkt
    v(90pt)
    text(size: 16pt, weight: "regular", upper(meta.degree))
    parbreak()

    // 14 pkt, pogrubienie, wyśrodkowanie, odstęp przed akapitem 60 pkt
    v(60pt)
    text(size: 14pt, weight: "bold", meta.author)
    parbreak()

    // 16 pkt, pogrubienie, wyśrodkowanie, odstęp przed akapitem 48 pkt (pisany bez cudzysłowów)
    v(48pt)
    text(size: 16pt, weight: "bold", meta.title)
    if meta.at("subtitle", default: none) != none {
      parbreak()
      v(12pt)
      text(size: 14pt, weight: "regular", meta.subtitle)
    }
    parbreak()
  })

  // 14 pkt, wyrównanie do prawej, odstęp przed akapitem 90 pkt + 14 pkt pogrubienie
  v(90pt)
  align(right, {
    text(size: 14pt, weight: "regular")[PROMOTOR:]
    parbreak()
    v(4pt)
    text(size: 14pt, weight: "bold", meta.supervisor)
    if meta.at("auxiliary-supervisor", default: none) != none {
      parbreak()
      v(14pt)
      text(size: 14pt, weight: "regular")[PROMOTOR POMOCNICZY:]
      parbreak()
      v(4pt)
      text(size: 14pt, weight: "bold", meta.auxiliary-supervisor)
    }
  })

  // 10 pkt, pogrubienie, wyśrodkowanie, odstęp przed akapitem 90 pkt
  v(1fr)
  v(90pt, weak: true)
  align(center, text(size: 10pt, weight: "bold", upper(meta.place + " " + meta.date)))
}

// Continuous page numbering is active throughout; front-matter and main-matter
// are kept as no-op wrappers so existing #show rules continue to work.
#let front-matter(body) = body
#let main-matter(body) = body

// Unnumbered chapter-level heading (included in TOC per Rysunek 2: Wstęp, Zakończenie, Bibliografia, Wykaz...).
#let unnumbered(title) = heading(level: 1, numbering: none, outlined: true, title)

#let abstract(body) = {
  unnumbered[Streszczenie]
  body
}

#let contents() = {
  heading(level: 1, numbering: none, outlined: false)[Spis treści]
  set par(first-line-indent: 0pt, leading: 0.8em)
  show outline.entry.where(level: 1): set block(above: 0.8em)
  show outline.entry.where(level: 1): set text(weight: "bold")
  outline(title: none, depth: 3, indent: 1.25cm)
}

#let figure-lists() = {
  unnumbered[Wykaz tabel, rysunków, wykresów i listingów]
  set par(first-line-indent: 0pt, leading: 0.8em)
  show outline.entry: it => link(it.element.location(), it.indented(it.prefix(), {
    strip-trailing-dot(it.element.caption.body)
    h(0.25em)
    box(width: 1fr, it.fill)
    h(0.25em)
    it.page()
  }))
  block(above: 1.2em, below: 0.6em, text(size: 14pt, weight: "bold")[Spis tabel])
  outline(title: none, target: figure.where(kind: table))
  block(above: 1.5em, below: 0.6em, text(size: 14pt, weight: "bold")[Spis rysunków])
  outline(title: none, target: figure.where(kind: image))
  block(above: 1.5em, below: 0.6em, text(size: 14pt, weight: "bold")[Spis wykresów])
  outline(title: none, target: figure.where(kind: "chart"))
  block(above: 1.5em, below: 0.6em, text(size: 14pt, weight: "bold")[Spis listingów])
  outline(title: none, target: figure.where(kind: raw))
}
