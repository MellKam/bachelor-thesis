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
// Tunable layout parameters — the values most likely to be dictated by a
// department. Change them here.
// ---------------------------------------------------------------------------
#let layout = (
  paper: "a4",
  margin: (left: 3.0cm, right: 2.5cm, top: 2.5cm, bottom: 2.5cm),  // wider left margin for binding
  serif: ("Liberation Serif", "Libertinus Serif"),
  sans: ("Liberation Sans", "Libertinus Serif"),
  mono: ("Liberation Mono", "DejaVu Sans Mono"),
  size: 12pt,
  leading: 0.7em,    // gap between lines (about 1.2 line spacing)
  spacing: 0.7em,    // gap between paragraphs
  indent: 1.5em,     // first-line indent
)

#let ink = black
#let muted = luma(90)
#let hairline = luma(200)
#let sans = layout.sans

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

// A three-line ("booktabs") table. Pass `table.header(...)` first.
#let booktable(..args) = {
  show table.cell.where(y: 0): set text(weight: "bold")
  set text(size: 0.92em)
  table(
    stroke: none,
    inset: (x: 6pt, y: 5pt),
    table.hline(stroke: 0.9pt),
    ..args,
    table.hline(stroke: 0.9pt),
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
    lang: meta.at("lang", default: "en"),
  )
  set par(
    justify: true,
    linebreaks: "optimized",
    leading: layout.leading,
    spacing: layout.spacing,
    first-line-indent: (amount: layout.indent, all: false),
  )

  // Page: a centred page number, nothing else.
  set page(
    paper: layout.paper,
    margin: layout.margin,
    footer: context {
      if here().page-numbering() == none { return }
      align(center, text(size: 0.85em, numbering(here().page-numbering(), ..counter(page).get())))
    },
  )

  // Headings: same family as the text, bold, left-aligned, never hyphenated.
  set heading(numbering: "1.1", supplement: [Section])
  show heading: set text(hyphenate: false)
  show heading: set par(justify: false, first-line-indent: 0pt, leading: 0.5em)
  let heading-block(it, size, above, below, style: "normal") = block(above: above, below: below, sticky: true, {
    set text(size: size, weight: "bold", style: style)
    if it.numbering != none {
      counter(heading).display(it.numbering)
      h(0.9em)
    }
    it.body
  })
  show heading.where(level: 2): it => heading-block(it, 14pt, 1.9em, 0.9em)
  show heading.where(level: 3): it => heading-block(it, 12pt, 1.6em, 0.7em)
  show heading.where(level: 4): it => heading-block(it, 12pt, 1.3em, 0.6em, style: "italic")

  // Chapters: a modest bold title on a fresh page, no ornament.
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    // Figure, table and listing numbers restart in every chapter.
    for kind in (image, table, raw) { counter(figure.where(kind: kind)).update(0) }
    v(1.5cm)
    heading-block(it, 20pt, 0pt, 1.1cm)
  }

  // Figures and tables: numbered per chapter (2.1, 2.2, ...); table captions on top.
  set figure(numbering: n => numbering("1.1", counter(heading).get().first(), n), gap: 1em)
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.caption: it => block(width: 92%, {
    set text(size: 10pt)
    set par(justify: false, first-line-indent: 0pt, leading: 0.55em)
    strong(it.supplement + [ ] + it.counter.display(it.numbering) + [.])
    h(0.4em)
    it.body
  })
  show figure: set block(above: 1.8em, below: 1.8em, breakable: false)
  set table(stroke: none)
  show table: set par(justify: false, first-line-indent: 0pt)

  // Code
  set raw(align: left)
  show raw: set text(font: layout.mono, size: 0.85em)
  show raw.where(block: false): it => box(fill: luma(240), outset: (x: 2pt, y: 3pt), radius: 2pt, it)
  show raw.where(block: true): it => block(
    width: 100%,
    fill: luma(248),
    stroke: 0.5pt + hairline,
    inset: (x: 10pt, y: 9pt),
    { set align(left); set par(first-line-indent: 0pt); it },
  )

  // Links stay in ink: external addresses are underlined, internal references are plain.
  show link: it => underline(offset: 2pt, stroke: 0.4pt + muted, it)
  show ref: it => {
    let el = it.element
    // A reference to a chapter reads "Chapter 2"; everything else keeps its supplement.
    if el != none and el.func() == heading and el.level == 1 and el.numbering != none {
      link(el.location())[Chapter #numbering(el.numbering, ..counter(heading).at(el.location()))]
    } else { it }
  }

  set list(indent: 1em, body-indent: 0.6em, spacing: 0.7em)
  set enum(indent: 1em, body-indent: 0.6em, spacing: 0.7em)

  body
}

// ---------------------------------------------------------------------------
// Front matter
// ---------------------------------------------------------------------------
#let title-page(meta) = {
  set page(numbering: none, footer: none)
  set par(justify: false, first-line-indent: 0pt, leading: 0.55em, spacing: 0pt)
  align(center, {
    text(size: 16pt, weight: "bold", meta.university)
    parbreak()
    v(0.5em)
    text(size: 13pt, meta.faculty)
    v(1fr)
    text(size: 13pt, meta.degree)
    parbreak()
    v(1em)
    text(size: 26pt, weight: "bold", meta.title)
    if meta.at("subtitle", default: none) != none {
      parbreak()
      v(0.9em)
      text(size: 15pt, style: "italic", meta.subtitle)
    }
    v(1fr)
  })
  grid(
    columns: (4cm, 1fr),
    row-gutter: 0.9em,
    [Author:], text(weight: "bold", meta.author),
    [Supervisor:], meta.supervisor,
    ..if meta.at("auxiliary-supervisor", default: none) != none {
      ([Auxiliary supervisor:], meta.auxiliary-supervisor)
    } else { () },
    [Programme:], meta.programme,
  )
  v(1.8cm)
  align(center, meta.place + ", " + meta.date)
}

// Roman page numbers for everything before Chapter 1.
#let front-matter(body) = {
  set page(numbering: "i")
  counter(page).update(1)
  body
}

// Arabic numbers from Chapter 1.
#let main-matter(body) = {
  set page(numbering: "1")
  counter(page).update(1)
  body
}

// Unnumbered chapter-level heading for abstract, bibliography, ...
#let unnumbered(title) = heading(level: 1, numbering: none, title)

#let abstract(body) = {
  unnumbered[Abstract]
  body
}

#let contents() = {
  heading(level: 1, numbering: none, outlined: false)[Contents]
  show outline.entry.where(level: 1): set block(above: 1em)
  show outline.entry.where(level: 1): set text(weight: "bold")
  outline(title: none, depth: 3, indent: 1.4em)
}

#let figure-lists() = {
  heading(level: 1, numbering: none, outlined: false)[List of figures]
  outline(title: none, target: figure.where(kind: image))
  heading(level: 1, numbering: none, outlined: false)[List of tables]
  outline(title: none, target: figure.where(kind: table))
}
